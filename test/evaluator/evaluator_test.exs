defmodule Scrapex.EvaluatorTest do
  use ExUnit.Case
  alias Scrapex.{Evaluator, AST, Value, Evaluator.Scope}

  describe "Literals and Variables" do
    test "evaluates variant literal" do
      ast_node = AST.variant("true")
      result = Evaluator.eval(ast_node)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates integer literal" do
      # Create an integer AST node
      ast_node = AST.integer(42)

      # Evaluate the AST node
      result = Evaluator.eval(ast_node)

      # Should return tagged integer value
      assert result == {:ok, Value.integer(42)}
    end

    test "evaluates float literal" do
      ast_node = AST.float(3.14)
      result = Evaluator.eval(ast_node)

      assert result == {:ok, Value.float(3.14)}
    end

    test "evaluates text literal" do
      ast_node = AST.text("hello")
      result = Evaluator.eval(ast_node)

      assert result == {:ok, Value.text("hello")}
    end

    test "returns error for unimplemented AST nodes" do
      # Use an AST node we haven't implemented yet
      unimplemented_node = {:some_future_feature, "test"}
      result = Evaluator.eval(unimplemented_node)

      assert {:error, "Unimplemented AST node: " <> _} = result
    end

    test "looks up variable from scope" do
      # Create identifier AST node
      ast_node = AST.identifier("x")

      # Create scope with variable binding
      scope =
        Scope.empty()
        |> Scope.bind("x", Value.integer(42))

      result = Evaluator.eval(ast_node, scope)

      # Should return the value from scope
      assert result == {:ok, Value.integer(42)}
    end

    test "returns error for undefined variable" do
      # Create identifier AST node for undefined variable
      ast_node = AST.identifier("undefined_var")

      # Use empty scope
      scope = Scope.empty()

      result = Evaluator.eval(ast_node, scope)

      # Should return error
      assert result == {:error, "Undefined variable: 'undefined_var'"}
    end

    test "looks up variable from parent scope" do
      # Test scope chain traversal
      ast_node = AST.identifier("x")

      # Create nested scopes
      scope =
        Scope.empty()
        # Parent scope
        |> Scope.bind("x", Value.integer(100))
        # Child scope
        |> Scope.bind("y", Value.integer(200))

      result = Evaluator.eval(ast_node, scope)

      # Should find x in parent scope
      assert result == {:ok, Value.integer(100)}
    end
  end

  describe "binary operations" do
    test "evaluates integer addition" do
      # 1 + 2
      ast_node = AST.binary_op(AST.integer(1), :plus, AST.integer(2))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(3)}
    end

    test "evaluates float addition" do
      # 1.5 + 2.3
      ast_node = AST.binary_op(AST.float(1.5), :plus, AST.float(2.3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.float(3.8)}
    end

    test "evaluates integer subtraction" do
      # 5 - 3
      ast_node = AST.binary_op(AST.integer(5), :minus, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(2)}
    end

    test "evaluates float subtraction" do
      # 5.7 - 3.2
      ast_node = AST.binary_op(AST.float(5.7), :minus, AST.float(3.2))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.float(2.5)}
    end

    test "evaluates integer multiplication" do
      # 4 * 3
      ast_node = AST.binary_op(AST.integer(4), :multiply, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(12)}
    end

    test "evaluates float multiplication" do
      # 4.0 * 3.5
      ast_node = AST.binary_op(AST.float(4.0), :multiply, AST.float(3.5))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.float(14.0)}
    end

    test "evaluates integer division" do
      # 6 / 2
      ast_node = AST.binary_op(AST.integer(6), :slash, AST.integer(2))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(3)}
    end

    test "evaluates float division" do
      # 9.0 / 3.0
      ast_node = AST.binary_op(AST.float(9.0), :slash, AST.float(3.0))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.float(3.0)}
    end

    test "evaluates text concatenation" do
      # "hello" ++ " world"
      ast_node = AST.binary_op(AST.text("hello"), :double_plus, AST.text(" world"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("hello world")}
    end

    test "evaluates binary operation with variables" do
      # x + y; x=10; y=20
      ast_node = AST.binary_op(AST.identifier("x"), :plus, AST.identifier("y"))

      scope =
        Scope.empty()
        |> Scope.bind("x", Value.integer(10))
        |> Scope.bind("y", Value.integer(20))

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(30)}
    end

    test "evaluates nested binary operations" do
      # (1 + 2) * 3
      inner = AST.binary_op(AST.integer(1), :plus, AST.integer(2))
      ast_node = AST.binary_op(inner, :multiply, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(9)}
    end

    test "returns error for type mismatch in binary operation" do
      # 1 + "hello" should fail
      ast_node = AST.binary_op(AST.integer(1), :plus, AST.text("hello"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error,
              "Operator '+' not supported between value '{:integer, 1}' and '{:text, \"hello\"}'"} =
               result
    end

    test "returns error for undefined variable in binary operation" do
      # x + 1 where x is undefined
      ast_node = AST.binary_op(AST.identifier("x"), :plus, AST.integer(1))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Undefined variable: 'x'"} = result
    end

    test "returns error for unimplemented binary operator" do
      # Test with an operator we haven't implemented
      ast_node = AST.binary_op(AST.integer(1), :some_future_op, AST.integer(2))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error,
              "Unimplemented AST node: {:binary_op, {:integer, 1}, :some_future_op, {:integer, 2}}"} =
               result
    end

    test "evaluates cons operation" do
      # 1 >+ [2, 3]
      list_ast = AST.list_literal([AST.integer(2), AST.integer(3)])
      ast_node = AST.binary_op(AST.integer(1), :cons, list_ast)
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected = Value.list([Value.integer(1), Value.integer(2), Value.integer(3)])
      assert result == {:ok, expected}
    end

    test "evaluates cons with variables" do
      # head >+ tail; head = 5; tail = [10, 15]
      ast_node = AST.binary_op(AST.identifier("head"), :cons, AST.identifier("tail"))

      scope =
        Scope.empty()
        |> Scope.bind("head", Value.integer(5))
        |> Scope.bind("tail", Value.list([Value.integer(10), Value.integer(15)]))

      result = Evaluator.eval(ast_node, scope)

      expected = Value.list([Value.integer(5), Value.integer(10), Value.integer(15)])
      assert result == {:ok, expected}
    end

    # TODO: type system not implemented yet!
    @tag :skip
    test "returns error for cons type mismatch" do
      # "hello" >+ [1, 2] should fail
      list_ast = AST.list_literal([AST.integer(1), AST.integer(2)])
      ast_node = AST.binary_op(AST.text("hello"), :cons, list_ast)
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, _reason} = result
    end
  end

  describe "where clauses" do
    test "evaluates simple where clause" do
      # x ; x = 42
      ast_node =
        AST.where(
          # body: x
          AST.identifier("x"),
          # binding: x = 42
          AST.binding("x", AST.integer(42))
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(42)}
    end

    test "evaluates where clause with dependency" do
      # y ; y = x + 5 ; x = 10
      ast_node =
        AST.where(
          # body: y
          AST.identifier("y"),
          AST.where(
            # binding: y = x + 5
            AST.binding(
              "y",
              AST.binary_op(
                AST.identifier("x"),
                :plus,
                AST.integer(5)
              )
            ),
            AST.binding("x", AST.integer(10))
          )
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(15)}
    end
  end
end
