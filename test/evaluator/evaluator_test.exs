defmodule Scrapex.EvaluatorTest do
  use ExUnit.Case
  alias Scrapex.{Evaluator, AST, Value, Evaluator.Scope}

  describe "eval/2" do
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
end
