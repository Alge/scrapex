defmodule Scrapex.Evaluator.ScopeTest do
  use ExUnit.Case

  alias Scrapex.Evaluator.{Scope}

  test "Create empty scope" do
    _scope = Scope.empty()
  end

  test "Empty scope should be empty" do
    scope = Scope.empty()

    assert scope.name == nil
    assert scope.value == nil
    assert scope.parent == nil
  end

  test "Binding a variable creates a new scope with correct name" do
    scope = Scope.empty()
    new_scope = Scope.bind(scope, "x", 1)
    assert new_scope.name == "x"
  end

  test "Binding a variable creates a new scope with correct value" do
    scope = Scope.empty()
    new_scope = Scope.bind(scope, "x", 1)
    assert new_scope.value == 1
  end

  test "Binding a variable creates a new scope with correct parent" do
    scope = Scope.empty()
    new_scope = Scope.bind(scope, "x", 1)
    assert new_scope.parent == scope
  end

  test "Get on empty scope returns error" do
    scope = Scope.empty()
    assert Scope.get(scope, "asd") == {:error, :not_found}
  end

  test "get on variable stored in first level of scope returns value" do
    scope = Scope.bind(Scope.empty(), "x", 1)
    assert Scope.get(scope, "x") == {:ok, 1}
  end

  test "get on variable stored in parent scope returns value" do
    # Create a nested scope storing y = 2, x = 1
    scope = Scope.bind(Scope.bind(Scope.empty(), "x", 1), "y", 2)
    assert Scope.get(scope, "x") == {:ok, 1}
    assert Scope.get(scope, "y") == {:ok, 2}
  end

  test "binding a variable with a existing name works" do
    scope = Scope.bind(Scope.bind(Scope.empty(), "x", 0), "x", 1)
    assert Scope.get(scope, "x") == {:ok, 1}
  end
end
