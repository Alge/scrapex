defmodule Scrapex.EvaluatorTest do
  use ExUnit.Case
  alias Scrapex.{Evaluator, AST, Value, Evaluator.Scope}

  describe "Literals and Variables" do
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
    @tag :skip
    test "evaluates integer addition" do
      # 1 + 2
      ast_node = AST.binary_op(AST.integer(1), :plus, AST.integer(2))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(3)}
    end

    @tag :skip
    test "evaluates integer subtraction" do
      # 5 - 3
      ast_node = AST.binary_op(AST.integer(5), :minus, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(2)}
    end

    @tag :skip
    test "evaluates integer multiplication" do
      # 4 * 3
      ast_node = AST.binary_op(AST.integer(4), :multiply, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(12)}
    end

    @tag :skip
    test "evaluates integer division" do
      # 6 / 2 (should return float in ScrapScript)
      ast_node = AST.binary_op(AST.integer(6), :slash, AST.integer(2))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.float(3.0)}
    end

    @tag :skip
    test "evaluates text concatenation" do
      # "hello" ++ " world"
      ast_node = AST.binary_op(AST.text("hello"), :double_plus, AST.text(" world"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("hello world")}
    end

    @tag :skip
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

    @tag :skip
    test "evaluates nested binary operations" do
      # (1 + 2) * 3
      inner = AST.binary_op(AST.integer(1), :plus, AST.integer(2))
      ast_node = AST.binary_op(inner, :multiply, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(9)}
    end

    @tag :skip
    test "returns error for type mismatch in binary operation" do
      # 1 + "hello" should fail
      ast_node = AST.binary_op(AST.integer(1), :plus, AST.text("hello"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Cannot add integer and text"} = result
    end

    @tag :skip
    test "returns error for undefined variable in binary operation" do
      # x + 1 where x is undefined
      ast_node = AST.binary_op(AST.identifier("x"), :plus, AST.integer(1))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Undefined variable: x"} = result
    end

    @tag :skip
    test "returns error for unimplemented binary operator" do
      # Test with an operator we haven't implemented
      ast_node = AST.binary_op(AST.integer(1), :some_future_op, AST.integer(2))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Unimplemented binary operator: some_future_op"} = result
    end
  end

  describe "where clauses" do
    @tag :skip
    test "evaluates simple where clause" do
      # x ; x = 42
      ast_node =
        AST.where(
          # body: x
          AST.identifier("x"),
          # binding: x = 42
          AST.binary_op(AST.identifier("x"), :equals, AST.integer(42))
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(42)}
    end

    @tag :skip
    test "evaluates where clause with dependency" do
      # y ; y = x + 5 ; x = 10
      ast_node =
        AST.where(
          # body: y
          AST.identifier("y"),
          AST.where(
            # binding: y = x + 5
            AST.binary_op(
              AST.identifier("y"),
              :equals,
              AST.binary_op(AST.identifier("x"), :plus, AST.integer(5))
            ),
            # binding: x = 10
            AST.binary_op(AST.identifier("x"), :equals, AST.integer(10))
          )
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(15)}
    end
  end
end
