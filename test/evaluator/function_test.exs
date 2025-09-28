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

      assert {:ok, {:function, nil, _, _}} = result
    end

    test "a function closure captures and uses variables from its definition scope" do
      # We will define a function `add_y` in a scope where `y = 100`.
      # Then, we will call this function in a different scope where `y` is
      # either different or doesn't exist, and prove that the function
      # still uses the original `y = 100`.

      # ScrapScript AST for: add_y 5
      # ; add_y = x -> x + y
      # ; y = 100

      function_def_ast =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :plus, AST.identifier("y"))
          )
        ])

      # Step 1: Define the function in an outer scope where `y = 100`.
      outer_scope = Scope.empty() |> Scope.bind("y", Value.integer(100))
      {:ok, add_y_function} = Evaluator.eval(function_def_ast, outer_scope)

      # Step 2: Create a completely different inner scope where `y` has a different value.
      # The call to the function will happen in this scope.
      inner_scope =
        Scope.empty()
        # This `y` should be ignored
        |> Scope.bind("y", Value.integer(999))
        |> Scope.bind("add_y", add_y_function)

      # Step 3: The AST for the function call itself: `add_y 5`
      call_ast = AST.function_app(AST.identifier("add_y"), AST.integer(5))

      # Step 4: Evaluate the function call in the `inner_scope`.
      result = Evaluator.eval(call_ast, inner_scope)

      # Assert that the result is 105 (5 + 100), proving that the function
      # used the `y` from its closure (the `outer_scope`), not the `y` from
      # the scope where it was called (the `inner_scope`).
      assert result == {:ok, Value.integer(105)}
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

    test "evaluates a simple recursive function (factorial)" do
      # fact 5 ; fact = | 0 -> 1 | n -> n * fact (n - 1)
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.integer(0), AST.integer(1)),
          AST.pattern_clause(
            AST.identifier("n"),
            AST.binary_op(
              AST.identifier("n"),
              :multiply,
              AST.function_app(
                AST.identifier("fact"),
                AST.binary_op(AST.identifier("n"), :minus, AST.integer(1))
              )
            )
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("fact"), AST.integer(5)),
          AST.binding("fact", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      # 5 * 4 * 3 * 2 * 1 = 120
      assert result == {:ok, Value.integer(120)}
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

    test "function with concatenation pattern captures prefix values" do
      # extract_and_sum [1, 2, 3, 4] ; extract_and_sum = [x, y] ++ rest -> x + y
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.concat_list_pattern(
              [AST.identifier("x"), AST.identifier("y")],
              AST.identifier("rest")
            ),
            AST.binary_op(AST.identifier("x"), :plus, AST.identifier("y"))
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("extract_and_sum"),
            AST.list_literal([AST.integer(1), AST.integer(2), AST.integer(3), AST.integer(4)])
          ),
          AST.binding("extract_and_sum", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      # Should return x + y = 1 + 2 = 3
      assert result == {:ok, Value.integer(3)}
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

  describe "variable consistency in patterns" do
    test "repeated variable in list pattern matches identical values" do
      # check_pair [3, 3] ; check_pair = | [x, x] -> x | _ -> 0
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([AST.identifier("x"), AST.identifier("x")]),
            AST.identifier("x")
          ),
          AST.pattern_clause(AST.wildcard(), AST.integer(0))
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("check_pair"),
            AST.list_literal([AST.integer(3), AST.integer(3)])
          ),
          AST.binding("check_pair", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(3)}
    end

    test "repeated variable in list pattern fails on different values" do
      # check_pair [1, 2] ; check_pair = | [x, x] -> x | _ -> 0
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([AST.identifier("x"), AST.identifier("x")]),
            AST.identifier("x")
          ),
          AST.pattern_clause(AST.wildcard(), AST.integer(0))
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("check_pair"),
            AST.list_literal([AST.integer(1), AST.integer(2)])
          ),
          AST.binding("check_pair", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      # Should fall through to wildcard case and return 0
      assert result == {:ok, Value.integer(0)}
    end

    test "repeated variable at non-adjacent positions" do
      # check_triple [5, 10, 5] ; check_triple = | [x, _, x] -> x | _ -> 0
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([
              AST.identifier("x"),
              AST.wildcard(),
              AST.identifier("x")
            ]),
            AST.identifier("x")
          ),
          AST.pattern_clause(AST.wildcard(), AST.integer(0))
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("check_triple"),
            AST.list_literal([AST.integer(5), AST.integer(10), AST.integer(5)])
          ),
          AST.binding("check_triple", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(5)}
    end

    test "repeated variable across cons and concat patterns" do
      # check_cons [7, 7, 8, 9] ; check_cons = | x >+ [x] ++ _ -> x | _ -> 0
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.cons_list_pattern(
              AST.identifier("x"),
              AST.concat_list_pattern([AST.identifier("x")], AST.wildcard())
            ),
            AST.identifier("x")
          ),
          AST.pattern_clause(AST.wildcard(), AST.integer(0))
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("check_cons"),
            AST.list_literal([AST.integer(7), AST.integer(7), AST.integer(8), AST.integer(9)])
          ),
          AST.binding("check_cons", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(7)}
    end

    test "repeated variable with different value types" do
      # check_text ["hello", "hello"] ; check_text = | [s, s] -> s | _ -> "no match"
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([AST.identifier("s"), AST.identifier("s")]),
            AST.identifier("s")
          ),
          AST.pattern_clause(AST.wildcard(), AST.text("no match"))
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("check_text"),
            AST.list_literal([AST.text("hello"), AST.text("hello")])
          ),
          AST.binding("check_text", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("hello")}
    end

    test "multiple distinct variables still work correctly" do
      # swap [1, 2] ; swap = | [x, y] -> [y, x]  (ensure normal behavior unaffected)
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([AST.identifier("x"), AST.identifier("y")]),
            AST.list_literal([AST.identifier("y"), AST.identifier("x")])
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(
            AST.identifier("swap"),
            AST.list_literal([AST.integer(1), AST.integer(2)])
          ),
          AST.binding("swap", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected = Value.list([Value.integer(2), Value.integer(1)])
      assert result == {:ok, expected}
    end

    test "pattern variables don't conflict with outer scope variables" do
      # result ; x = 5 ; result = check_pair [3, 3] ; check_pair = | [x, x] -> x | _ -> 0
      # The pattern [x, x] should create local x bindings, not conflict with outer x = 5

      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([AST.identifier("x"), AST.identifier("x")]),
            AST.identifier("x")
          ),
          AST.pattern_clause(AST.wildcard(), AST.integer(0))
        ])

      ast_node =
        AST.where(
          AST.identifier("result"),
          AST.where(
            AST.binding("x", AST.integer(5)),
            AST.where(
              AST.binding(
                "result",
                AST.function_app(
                  AST.identifier("check_pair"),
                  AST.list_literal([AST.integer(3), AST.integer(3)])
                )
              ),
              AST.binding("check_pair", function_def)
            )
          )
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      # Should return 3 (from the pattern match), not fail due to outer x = 5
      assert result == {:ok, Value.integer(3)}
    end
  end

  describe "destructuring record patterns" do
    test "function with simple record pattern matching" do
      # get_name {name = "John", age = 30} ; get_name = | {name = n} -> n
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.record_pattern([AST.record_pattern_field("name", AST.identifier("n"))]),
            AST.identifier("n")
          )
        ])

      record_arg =
        AST.record_literal([
          AST.record_expression_field("name", AST.text("John")),
          AST.record_expression_field("age", AST.integer(30))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("get_name"), record_arg),
          AST.binding("get_name", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("John")}
    end

    test "function with record pattern matching multiple fields" do
      # add_coords {x = 3, y = 5, z = 0} ; add_coords = | {x = a, y = b} -> a + b
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.record_pattern([
              AST.record_pattern_field("x", AST.identifier("a")),
              AST.record_pattern_field("y", AST.identifier("b"))
            ]),
            AST.binary_op(AST.identifier("a"), :plus, AST.identifier("b"))
          )
        ])

      record_arg =
        AST.record_literal([
          AST.record_expression_field("x", AST.integer(3)),
          AST.record_expression_field("y", AST.integer(5)),
          AST.record_expression_field("z", AST.integer(0))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("add_coords"), record_arg),
          AST.binding("add_coords", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(8)}
    end

    test "function with record pattern matching literal values" do
      # check_status {status = #ok} ; check_status = | {status = #ok} -> #true | _ -> #false
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.record_pattern([AST.record_pattern_field("status", AST.variant("ok"))]),
            AST.variant("true")
          ),
          AST.pattern_clause(AST.wildcard(), AST.variant("false"))
        ])

      record_arg =
        AST.record_literal([
          AST.record_expression_field("status", AST.variant("ok"))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("check_status"), record_arg),
          AST.binding("check_status", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "function with record rest pattern" do
      # get_rest {a=1, b=2, c=3} ; get_rest = | {a = _, ..rest} -> rest
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.record_pattern([
              AST.record_pattern_field("a", AST.wildcard()),
              AST.record_rest("rest")
            ]),
            AST.identifier("rest")
          )
        ])

      record_arg =
        AST.record_literal([
          AST.record_expression_field("a", AST.integer(1)),
          AST.record_expression_field("b", AST.integer(2)),
          AST.record_expression_field("c", AST.integer(3))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("get_rest"), record_arg),
          AST.binding("get_rest", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected_rest = Value.record([{"b", Value.integer(2)}, {"c", Value.integer(3)}])
      assert result == {:ok, expected_rest}
    end

    test "record pattern fails if a field is missing" do
      # check {a=1} ; check = | {a=_, b=_} -> #yes | _ -> #no
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.record_pattern([
              AST.record_pattern_field("a", AST.wildcard()),
              AST.record_pattern_field("b", AST.wildcard())
            ]),
            AST.variant("yes")
          ),
          AST.pattern_clause(AST.wildcard(), AST.variant("no"))
        ])

      record_arg =
        AST.record_literal([AST.record_expression_field("a", AST.integer(1))])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("check"), record_arg),
          AST.binding("check", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      # Should fall back to the wildcard and return #no
      assert result == {:ok, Value.variant("no")}
    end

    test "record pattern fails if a literal value does not match" do
      # check {status = #err} ; check = | {status = #ok} -> #yes | _ -> #no
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.record_pattern([AST.record_pattern_field("status", AST.variant("ok"))]),
            AST.variant("yes")
          ),
          AST.pattern_clause(AST.wildcard(), AST.variant("no"))
        ])

      record_arg =
        AST.record_literal([AST.record_expression_field("status", AST.variant("err"))])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("check"), record_arg),
          AST.binding("check", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("no")}
    end

    test "function with nested record and list patterns" do
      # process { data = [1, { value = 42 }] }
      # process = | { data = [_, { value = v }] } -> v
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.record_pattern([
              AST.record_pattern_field(
                "data",
                AST.regular_list_pattern([
                  AST.wildcard(),
                  AST.record_pattern([
                    AST.record_pattern_field("value", AST.identifier("v"))
                  ])
                ])
              )
            ]),
            AST.identifier("v")
          )
        ])

      inner_record =
        AST.record_literal([
          AST.record_expression_field("value", AST.integer(42))
        ])

      record_arg =
        AST.record_literal([
          AST.record_expression_field(
            "data",
            AST.list_literal([AST.integer(1), inner_record])
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("process"), record_arg),
          AST.binding("process", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(42)}
    end
  end

  describe "destructuring variant patterns" do
    test "function with simple variant tag matching" do
      # check #ok ; check = | #ok -> #success | #err -> #failure
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.variant("ok"), AST.variant("success")),
          AST.pattern_clause(AST.variant("err"), AST.variant("failure"))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("check"), AST.variant("ok")),
          AST.binding("check", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("success")}
    end

    test "function with variant pattern that destructures a payload" do
      # We want to test: get_value <some_value>
      # where get_value = | #some v -> v
      # and <some_value> is a runtime value {:variant, "some", {:integer, 42}}

      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.variant_pattern(AST.identifier("some"), [AST.identifier("v")]),
            AST.identifier("v")
          ),
          AST.pattern_clause(AST.variant_pattern(AST.identifier("none"), []), AST.integer(0))
        ])

      # The ScrapScript code we will evaluate is: get_value my_arg
      ast_node = AST.function_app(AST.identifier("get_value"), AST.identifier("my_arg"))

      # Manually create the rich variant value we can't parse from source yet.
      # No helper module needed.
      arg_value = {:variant, "some", Value.integer(42)}

      # Create a scope where BOTH the function and its argument are pre-defined.
      scope =
        Scope.empty()
        |> Scope.bind("get_value", Value.function(function_def, Scope.empty()))
        |> Scope.bind("my_arg", arg_value)

      # Evaluate the AST through the public API
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(42)}
    end

    test "variant pattern fails if tag does not match" do
      # check #err ; check = | #ok -> #success | _ -> #failure
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.variant("ok"), AST.variant("success")),
          AST.pattern_clause(AST.wildcard(), AST.variant("failure"))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("check"), AST.variant("err")),
          AST.binding("check", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("failure")}
    end

    test "function with nested variant and record patterns" do
      # Test: process my_arg
      # where process = | #ok { data = d } -> d
      # and my_arg is {:variant, "ok", {:record, [{"data", ...}]}}
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.variant_pattern(AST.identifier("ok"), [
              AST.record_pattern([AST.record_pattern_field("data", AST.identifier("d"))])
            ]),
            AST.identifier("d")
          )
        ])

      ast_node = AST.function_app(AST.identifier("process"), AST.identifier("my_arg"))

      record_payload = Value.record([{"data", Value.text("hello")}])
      arg_value = {:variant, "ok", record_payload}

      scope =
        Scope.empty()
        |> Scope.bind("process", Value.function(function_def, Scope.empty()))
        |> Scope.bind("my_arg", arg_value)

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("hello")}
    end

    test "variant pattern with payload fails if value has no payload" do
      # Test: process #some
      # where process = | #some v -> v | _ -> #fallback
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.variant_pattern(AST.identifier("some"), [AST.identifier("v")]),
            AST.identifier("v")
          ),
          # Add a wildcard to catch all other cases
          AST.pattern_clause(AST.wildcard(), AST.variant("fallback"))
        ])

      ast_node = AST.function_app(AST.identifier("process"), AST.identifier("my_arg"))
      # This creates {:variant, "some", nil}
      arg_value = Value.variant("some")

      scope =
        Scope.empty()
        |> Scope.bind("process", Value.function(function_def, Scope.empty()))
        |> Scope.bind("my_arg", arg_value)

      result = Evaluator.eval(ast_node, scope)

      # It should fail the first clause and fall through to the wildcard.
      assert result == {:ok, Value.variant("fallback")}
    end

    test "variant pattern without payload fails if value has a payload" do
      # Test: is_none my_arg
      # where is_none = | #none -> #true | _ -> #false
      # and my_arg is a #none value that is incorrectly carrying data.
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.variant_pattern(AST.identifier("none"), []),
            AST.variant("true")
          ),
          AST.pattern_clause(AST.wildcard(), AST.variant("false"))
        ])

      ast_node = AST.function_app(AST.identifier("is_none"), AST.identifier("my_arg"))

      # Manually create the malformed value.
      arg_value = {:variant, "none", Value.integer(123)}

      scope =
        Scope.empty()
        |> Scope.bind("is_none", Value.function(function_def, Scope.empty()))
        |> Scope.bind("my_arg", arg_value)

      result = Evaluator.eval(ast_node, scope)

      # It should fail the first clause and fall through to the wildcard.
      assert result == {:ok, Value.variant("false")}
    end
  end

  describe "destructuring text patterns" do
    test "function with text pattern that captures the rest of the text" do
      # Test: get_name "Hello, Alice"
      # where get_name = | "Hello, " ++ name -> name
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.text_pattern(AST.text("Hello, "), AST.identifier("name")),
            AST.identifier("name")
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("get_name"), AST.text("Hello, Alice")),
          AST.binding("get_name", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("Alice")}
    end

    test "text pattern fails if prefix does not match" do
      # Test: get_name "Goodbye, Bob"
      # where get_name = | "Hello, " ++ _ -> #ok | _ -> #fail
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.text_pattern(AST.text("Hello, "), AST.wildcard()),
            AST.variant("ok")
          ),
          AST.pattern_clause(AST.wildcard(), AST.variant("fail"))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("get_name"), AST.text("Goodbye, Bob")),
          AST.binding("get_name", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      # Should fail the first clause and fall through to the wildcard
      assert result == {:ok, Value.variant("fail")}
    end

    test "text pattern with an empty prefix matches and captures everything" do
      # Test: capture_all "anything"
      # where capture_all = | "" ++ s -> s
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.text_pattern(AST.text(""), AST.identifier("s")),
            AST.identifier("s")
          )
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("capture_all"), AST.text("anything")),
          AST.binding("capture_all", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("anything")}
    end

    test "text pattern fails if the value is not text" do
      # Test: get_name 123
      # where get_name = | "Hello, " ++ _ -> #ok | _ -> #fail
      function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.text_pattern(AST.text("Hello, "), AST.wildcard()),
            AST.variant("ok")
          ),
          AST.pattern_clause(AST.wildcard(), AST.variant("fail"))
        ])

      ast_node =
        AST.where(
          AST.function_app(AST.identifier("get_name"), AST.integer(123)),
          AST.binding("get_name", function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("fail")}
    end
  end

  describe "higher-order functions" do
    test "a function can take another function as an argument and apply it" do
      # ScrapScript code being tested:
      # apply (x -> x * 2) 5
      # ; apply = f -> x -> f x

      # AST for the `apply` function definition: f -> x -> f x
      # This is a nested pattern match expression.
      apply_function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("f"),
            AST.pattern_match_expression([
              AST.pattern_clause(
                AST.identifier("x"),
                AST.function_app(AST.identifier("f"), AST.identifier("x"))
              )
            ])
          )
        ])

      # AST for the lambda function (the first argument): x -> x * 2
      double_function_def =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :multiply, AST.integer(2))
          )
        ])

      # AST for the main expression body: apply (x -> x * 2) 5
      # This is a curried application: ((apply double_function) 5)
      body_ast =
        AST.function_app(
          AST.function_app(AST.identifier("apply"), double_function_def),
          AST.integer(5)
        )

      # The final, complete AST with the where clause
      ast_node =
        AST.where(
          body_ast,
          AST.binding("apply", apply_function_def)
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(10)}
    end
  end
end
