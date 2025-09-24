# test/evaluator/list_test.exs
defmodule Scrapex.Evaluator.ListTest do
  use ExUnit.Case
  alias Scrapex.{Evaluator, AST, Value, Evaluator.Scope}

  describe "list literal evaluation" do
    test "evaluates empty list literal" do
      # []
      ast_node = AST.list_literal([])
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.list([])}
    end

    test "evaluates list with single integer" do
      # [42]
      ast_node = AST.list_literal([AST.integer(42)])
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected = Value.list([Value.integer(42)])
      assert result == {:ok, expected}
    end

    test "evaluates list with integer literals" do
      # [1, 2, 3]
      ast_node =
        AST.list_literal([
          AST.integer(1),
          AST.integer(2),
          AST.integer(3)
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          Value.integer(1),
          Value.integer(2),
          Value.integer(3)
        ])

      assert result == {:ok, expected}
    end

    test "evaluates list with float literals" do
      # [1.0, 2.5, 3.14]
      ast_node =
        AST.list_literal([
          AST.float(1.0),
          AST.float(2.5),
          AST.float(3.14)
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          Value.float(1.0),
          Value.float(2.5),
          Value.float(3.14)
        ])

      assert result == {:ok, expected}
    end

    test "evaluates list with text literals" do
      # ["hello", "world"]
      ast_node =
        AST.list_literal([
          AST.text("hello"),
          AST.text("world")
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          Value.text("hello"),
          Value.text("world")
        ])

      assert result == {:ok, expected}
    end

    test "evaluates list with expressions" do
      # [1 + 2, 3 * 4]
      ast_node =
        AST.list_literal([
          AST.binary_op(AST.integer(1), :plus, AST.integer(2)),
          AST.binary_op(AST.integer(3), :multiply, AST.integer(4))
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          Value.integer(3),
          Value.integer(12)
        ])

      assert result == {:ok, expected}
    end

    test "evaluates list with variables from scope" do
      # [x, y] where x = 10, y = 20
      ast_node =
        AST.list_literal([
          AST.identifier("x"),
          AST.identifier("y")
        ])

      scope =
        Scope.empty()
        |> Scope.bind("x", Value.integer(10))
        |> Scope.bind("y", Value.integer(20))

      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          Value.integer(10),
          Value.integer(20)
        ])

      assert result == {:ok, expected}
    end

    test "returns error when list element evaluation fails" do
      # [x] where x is undefined
      ast_node =
        AST.list_literal([
          AST.identifier("undefined_var")
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:error, "Undefined variable: 'undefined_var'"}
    end

    test "evaluates nested list literals" do
      # [[1, 2], [3, 4]]
      ast_node =
        AST.list_literal([
          AST.list_literal([AST.integer(1), AST.integer(2)]),
          AST.list_literal([AST.integer(3), AST.integer(4)])
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          Value.list([Value.integer(1), Value.integer(2)]),
          Value.list([Value.integer(3), Value.integer(4)])
        ])

      assert result == {:ok, expected}
    end

    test "evaluates list with complex where-clause variables" do
      # [a, b] ; a = x + 1 ; b = y * 2 ; x = 5 ; y = 3
      body = AST.list_literal([AST.identifier("a"), AST.identifier("b")])

      bindings =
        AST.where(
          AST.binding("a", AST.binary_op(AST.identifier("x"), :plus, AST.integer(1))),
          AST.where(
            AST.binding("b", AST.binary_op(AST.identifier("y"), :multiply, AST.integer(2))),
            AST.where(
              AST.binding("x", AST.integer(5)),
              AST.binding("y", AST.integer(3))
            )
          )
        )

      ast_node = AST.where(body, bindings)
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          # a = x + 1 = 5 + 1
          Value.integer(6),
          # b = y * 2 = 3 * 2
          Value.integer(6)
        ])

      assert result == {:ok, expected}
    end

    # Future type checking tests
    @tag :skip
    test "returns error for mixed types in list" do
      # [1, 2.5, "hello"] - should be type error in ScrapScript
      ast_node =
        AST.list_literal([
          AST.integer(1),
          AST.float(2.5),
          AST.text("hello")
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, message} = result
      assert String.contains?(message, "type mismatch")
    end

    @tag :skip
    test "returns error for integer and float in same list" do
      # [1, 1.0] - different numeric types
      ast_node =
        AST.list_literal([
          AST.integer(1),
          AST.float(1.0)
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, message} = result
      assert String.contains?(message, "type mismatch")
    end
  end
end
