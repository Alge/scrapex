defmodule Scrapex.Value.FunctionTest do
  use ExUnit.Case

  alias Scrapex.Value
  alias Scrapex.Evaluator.Scope

  describe "function values" do
    test "create function value" do
      pattern_expr = {:pattern_match_expression, []}
      scope = Scope.empty()

      assert Value.function(pattern_expr, scope) == {:function, nil, pattern_expr, scope}
    end

    test "display function value" do
      pattern_expr = {:pattern_match_expression, []}
      scope = Scope.empty()
      function_value = Value.function(pattern_expr, scope)

      assert Value.display(function_value) == {:ok, "<function>"}
    end

    test "display! function value" do
      pattern_expr = {:pattern_match_expression, []}
      scope = Scope.empty()
      function_value = Value.function(pattern_expr, scope)

      assert Value.display!(function_value) == "<function>"
    end
  end
end
