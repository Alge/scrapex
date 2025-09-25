# test/evaluator/function_test.exs
defmodule Scrapex.Evaluator.FunctionTest do
  use ExUnit.Case
  alias Scrapex.{Evaluator, AST, Value, Evaluator.Scope}

  describe "function value creation" do
    test "evaluates pattern match expression as function value" do
      # | x -> x (identity function)
      ast_node =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.identifier("x"), AST.identifier("x"))
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:ok, {:function, _, _}} = result
    end

    test "function value captures current scope" do
      # | x -> x + y  (where y is from outer scope)
      ast_node =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :plus, AST.identifier("y"))
          )
        ])

      scope = Scope.empty() |> Scope.bind("y", Value.integer(10))
      result = Evaluator.eval(ast_node, scope)

      assert {:ok, {:function, pattern_expr, captured_scope}} = result
      assert Scope.get(captured_scope, "y") == {:ok, Value.integer(10)}
    end
  end

  describe "simple function application" do
    test "applies identity function to integer" do
      # (x -> x) 42
      function_expr =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.identifier("x"), AST.identifier("x"))
        ])

      ast_node = AST.function_app(function_expr, AST.integer(42))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(42)}
    end

    test "applies function with arithmetic body" do
      # (x -> x + 1) 5
      function_expr =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :plus, AST.integer(1))
          )
        ])

      ast_node = AST.function_app(function_expr, AST.integer(5))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(6)}
    end

    test "applies function bound in where clause" do
      # f 10 ; f = x -> x * 2
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :multiply, AST.integer(2))
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("f"), AST.integer(10)),
          AST.binding("f", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(20)}
    end
  end

  describe "function closures" do
    test "function captures variables from defining scope" do
      # f 5 ; f = x -> x + y ; y = 100
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :plus, AST.identifier("y"))
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("f"), AST.integer(5)),
          AST.where(
            AST.binding("f", function_def),
            AST.binding("y", AST.integer(100))
          )
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(105)}
    end
  end

  describe "pattern matching in functions" do
    test "function with multiple pattern clauses" do
      # f 2 ; f = | 1 -> "one" | 2 -> "two" | _ -> "other"
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.integer(1), AST.text("one")),
          AST.pattern_clause(AST.integer(2), AST.text("two")),
          AST.pattern_clause(AST.wildcard(), AST.text("other"))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("f"), AST.integer(2)),
          AST.binding("f", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("two")}
    end

    test "function with wildcard fallback" do
      # f 99 ; f = | 1 -> "one" | _ -> "other"
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.integer(1), AST.text("one")),
          AST.pattern_clause(AST.wildcard(), AST.text("other"))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("f"), AST.integer(99)),
          AST.binding("f", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("other")}
    end

    test "function with list patterns" do
      # is_empty [] ; is_empty = | [] -> #true | _ -> #false
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.empty_list(), AST.variant("true")),
          AST.pattern_clause(AST.wildcard(), AST.variant("false"))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("is_empty"), AST.list_literal([])),
          AST.binding("is_empty", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end
  end

  describe "curried functions" do
    test "applies curried function step by step" do
      # add 3 5 ; add = x -> y -> x + y
      inner_function =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("y"),
            AST.binary_op(AST.identifier("x"), :plus, AST.identifier("y"))
          )
        ])

      outer_function =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.identifier("x"), inner_function)
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.function_app(AST.identifier("add"), AST.integer(3)),
            AST.integer(5)
          ),
          AST.binding("add", outer_function)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(8)}
    end
  end

  describe "error cases" do
    test "returns error for non-exhaustive patterns" do
      # f 3 ; f = | 1 -> "one" | 2 -> "two"  (no pattern matches 3)
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.integer(1), AST.text("one")),
          AST.pattern_clause(AST.integer(2), AST.text("two"))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("f"), AST.integer(3)),
          AST.binding("f", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, message} = result
      assert String.contains?(message, "No pattern matched")
    end

    test "returns error when applying non-function" do
      # 42 5  (trying to apply integer as function)
      ast_node = AST.function_app(AST.integer(42), AST.integer(5))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, message} = result
      assert String.contains?(message, "Cannot apply")
    end
  end

  describe "destructuring patterns" do
    test "function with 2-element list destructuring" do
      # sum_pair [3, 4] ; sum_pair = [x, y] -> x + y
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([AST.identifier("x"), AST.identifier("y")]),
            AST.binary_op(AST.identifier("x"), :plus, AST.identifier("y"))
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("sum_pair"),
            AST.list_literal([AST.integer(3), AST.integer(4)])
          ),
          AST.binding("sum_pair", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(7)}
    end

    test "function with 3-element list destructuring" do
      # first_of_three [1, 2, 3] ; first_of_three = [x, _, _] -> x
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([AST.identifier("x"), AST.wildcard(), AST.wildcard()]),
            AST.identifier("x")
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("first_of_three"),
            AST.list_literal([AST.integer(1), AST.integer(2), AST.integer(3)])
          ),
          AST.binding("first_of_three", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(1)}
    end

    test "function with head/tail destructuring" do
      # head [1, 2, 3] ; head = h >+ _ -> h
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.cons_list_pattern(AST.identifier("h"), AST.wildcard()),
            AST.identifier("h")
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("head"),
            AST.list_literal([AST.integer(1), AST.integer(2), AST.integer(3)])
          ),
          AST.binding("head", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(1)}
    end

    test "function with tail extraction" do
      # tail [1, 2, 3] ; tail = _ >+ t -> t
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.cons_list_pattern(AST.wildcard(), AST.identifier("t")),
            AST.identifier("t")
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("tail"),
            AST.list_literal([AST.integer(1), AST.integer(2), AST.integer(3)])
          ),
          AST.binding("tail", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected_tail = Value.list([Value.integer(2), Value.integer(3)])
      assert result == {:ok, expected_tail}
    end

    test "function with concatenation pattern" do
      # skip_two [1, 2, 3, 4] ; skip_two = [_, _] ++ rest -> rest
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.concat_list_pattern([AST.wildcard(), AST.wildcard()], AST.identifier("rest")),
            AST.identifier("rest")
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("skip_two"),
            AST.list_literal([AST.integer(1), AST.integer(2), AST.integer(3), AST.integer(4)])
          ),
          AST.binding("skip_two", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected_rest = Value.list([Value.integer(3), Value.integer(4)])
      assert result == {:ok, expected_rest}
    end

    test "function with nested destructuring" do
      # process_pairs [[1, 2], [3, 4]] ; process_pairs = [[a, b], [c, d]] -> a + b + c + d
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([
              AST.regular_list_pattern([AST.identifier("a"), AST.identifier("b")]),
              AST.regular_list_pattern([AST.identifier("c"), AST.identifier("d")])
            ]),
            AST.binary_op(
              AST.binary_op(
                AST.binary_op(AST.identifier("a"), :plus, AST.identifier("b")),
                :plus,
                AST.identifier("c")
              ),
              :plus,
              AST.identifier("d")
            )
          )
        ])

      inner_list1 = AST.list_literal([AST.integer(1), AST.integer(2)])
      inner_list2 = AST.list_literal([AST.integer(3), AST.integer(4)])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("process_pairs"),
            AST.list_literal([inner_list1, inner_list2])
          ),
          AST.binding("process_pairs", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(10)}
    end

    # Error cases
    test "destructuring fails when list length doesn't match pattern" do
      # sum_pair [1] ; sum_pair = [x, y] -> x + y  (should fail - list too short)
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([AST.identifier("x"), AST.identifier("y")]),
            AST.binary_op(AST.identifier("x"), :plus, AST.identifier("y"))
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("sum_pair"), AST.list_literal([AST.integer(1)])),
          AST.binding("sum_pair", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, message} = result
      assert String.contains?(message, "No pattern matched")
    end

    test "head/tail destructuring fails on empty list" do
      # head [] ; head = h >+ t -> h  (should fail - empty list has no head)
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.cons_list_pattern(AST.identifier("h"), AST.identifier("t")),
            AST.identifier("h")
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("head"), AST.list_literal([])),
          AST.binding("head", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, message} = result
      assert String.contains?(message, "No pattern matched")
    end
  end

  describe "pattern matching empty lists" do
    test "empty list pattern matches empty list argument" do
      # Test: (| [] -> "empty") []
      function_expr =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.empty_list(), AST.text("empty"))
        ])

      ast_node = AST.function_app(function_expr, AST.list_literal([]))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("empty")}
    end

    test "empty list pattern does not match non-empty list" do
      # Test: (| [] -> "empty" | _ -> "not empty") [1]
      function_expr =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.empty_list(), AST.text("empty")),
          AST.pattern_clause(AST.wildcard(), AST.text("not empty"))
        ])

      ast_node = AST.function_app(function_expr, AST.list_literal([AST.integer(1)]))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("not empty")}
    end
  end

  describe "higher-order functions" do
    @tag :skip
    test "function that takes function as argument" do
      # apply (x -> x * 2) 5 ; apply = f -> x -> f x
      # This is complex - function taking function and returning function
      ast_node = :complex_higher_order_test
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(10)}
    end
  end
end
