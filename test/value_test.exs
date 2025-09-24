defmodule Scrapex.ValueTest do
  use ExUnit.Case

  alias Scrapex.Value
  alias Scrapex.Evaluator.Scope

  describe "Evaluate values" do
    test "Create integer value" do
      assert Value.integer(123) == {:integer, 123}
    end

    test "Create float value" do
      assert Value.float(12.3) == {:float, 12.3}
    end

    test "Create text value" do
      assert Value.text("Hello!") == {:text, "Hello!"}
    end
  end

  describe "Function values" do
    test "create function value" do
      pattern_expr = {:pattern_match_expression, []}
      scope = Scope.empty()

      assert Value.function(pattern_expr, scope) == {:function, pattern_expr, scope}
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

  describe "Display string representation for values" do
    test "display integer" do
      assert Value.display!(Value.integer(123)) == "123"
    end

    test "display float" do
      assert Value.display!(Value.float(1.23)) == "1.23"
    end

    test "display text" do
      assert Value.display!(Value.text("Hello")) == "Hello"
    end

    test "display! empty list" do
      assert Value.display!(Value.list([])) == "[]"
    end

    test "display! list with multiple integers" do
      list_value =
        Value.list([
          Value.integer(1),
          Value.integer(2),
          Value.integer(3)
        ])

      assert Value.display!(list_value) == "[1, 2, 3]"
    end

    test "display list with floats" do
      list_value =
        Value.list([
          Value.float(1.5),
          Value.float(2.7)
        ])

      assert Value.display(list_value) == {:ok, "[1.5, 2.7]"}
    end

    test "display! list with text values" do
      list_value =
        Value.list([
          Value.text("hello"),
          Value.text("world")
        ])

      assert Value.display!(list_value) == "[hello, world]"
    end

    test "display! nested lists" do
      inner_list1 = Value.list([Value.integer(1), Value.integer(2)])
      inner_list2 = Value.list([Value.integer(3), Value.integer(4)])
      outer_list = Value.list([inner_list1, inner_list2])

      assert Value.display!(outer_list) == "[[1, 2], [3, 4]]"
    end

    test "display crashes on unimplemented type" do
      # Test that it raises any exception
      assert_raise RuntimeError, fn ->
        Value.display!({:not_implemented, 123})
      end
    end
  end

  describe "Variant values" do
    test "create variant value" do
      assert Value.variant("true") == {:variant, "true"}
    end

    test "display variant value" do
      variant_value = Value.variant("success")
      assert Value.display(variant_value) == {:ok, "#success"}
    end

    test "display! variant value" do
      variant_value = Value.variant("error")
      assert Value.display!(variant_value) == "#error"
    end

    test "negate returns error for variant" do
      variant_value = Value.variant("true")
      result = Value.negate(variant_value)
      assert {:error, _reason} = result
    end

    test "negate! raises error for variant" do
      variant_value = Value.variant("false")

      assert_raise RuntimeError, fn ->
        Value.negate!(variant_value)
      end
    end
  end

  describe "Test operators applied to values" do
    ############## Plus ##############
    test "integer plus integer" do
      assert Value.add!(Value.integer(1), Value.integer(4)) == Value.integer(5)
    end

    test "float plus float" do
      assert Value.add!(Value.float(1.5), Value.float(4.1)) == Value.float(5.6)
    end

    ############## Minus ##############
    test "integer minus integer" do
      assert Value.subtract!(Value.integer(10), Value.integer(3)) == Value.integer(7)
    end

    test "float minus float" do
      assert Value.subtract!(Value.float(5.5), Value.float(2.2)) == Value.float(3.3)
    end

    ############## Multiply ##############
    test "integer multiply integer" do
      assert Value.multiply!(Value.integer(3), Value.integer(4)) == Value.integer(12)
    end

    test "float multiply float" do
      assert Value.multiply!(Value.float(2.5), Value.float(3.0)) == Value.float(7.5)
    end

    ############## Divide ##############
    test "integer divide integer returns integer" do
      assert Value.divide!(Value.integer(6), Value.integer(2)) == Value.integer(3)
    end

    test "integer divide integer floors positive result" do
      assert Value.divide!(Value.integer(7), Value.integer(2)) == Value.integer(3)
    end

    test "integer divide integer floors toward negative infinity" do
      assert Value.divide!(Value.integer(-7), Value.integer(2)) == Value.integer(-4)
    end

    test "integer divide integer floors negative dividend" do
      assert Value.divide!(Value.integer(7), Value.integer(-2)) == Value.integer(-4)
    end

    test "integer divide integer floors both negative" do
      assert Value.divide!(Value.integer(-7), Value.integer(-2)) == Value.integer(3)
    end

    test "integer divide by zero raises error" do
      assert_raise RuntimeError, "Division by zero", fn ->
        Value.divide!(Value.integer(5), Value.integer(0))
      end
    end

    test "float divide by zero raises error" do
      assert_raise RuntimeError, "Division by zero", fn ->
        Value.divide!(Value.float(5.0), Value.float(0.0))
      end
    end

    test "float divide float" do
      assert Value.divide!(Value.float(9.0), Value.float(3.0)) == Value.float(3.0)
    end

    ############## Append ##############
    test "text append text" do
      assert Value.append!(Value.text("Hello "), Value.text("World")) == Value.text("Hello World")
    end

    ############## Negate ##############
    test "integer negate positive" do
      assert Value.negate(Value.integer(42)) == {:ok, Value.integer(-42)}
    end

    test "integer negate negative" do
      assert Value.negate(Value.integer(-42)) == {:ok, Value.integer(42)}
    end

    test "integer negate zero" do
      assert Value.negate(Value.integer(0)) == {:ok, Value.integer(0)}
    end

    test "float negate positive" do
      assert Value.negate(Value.float(3.14)) == {:ok, Value.float(-3.14)}
    end

    test "float negate negative" do
      assert Value.negate(Value.float(-2.71)) == {:ok, Value.float(2.71)}
    end

    test "float negate zero" do
      assert Value.negate(Value.float(0.0)) == {:ok, Value.float(-0.0)}
    end

    test "negate! integer positive" do
      assert Value.negate!(Value.integer(42)) == Value.integer(-42)
    end

    test "negate! integer negative" do
      assert Value.negate!(Value.integer(-42)) == Value.integer(42)
    end

    test "negate! float positive" do
      assert Value.negate!(Value.float(3.14)) == Value.float(-3.14)
    end

    test "negate! float negative" do
      assert Value.negate!(Value.float(-2.71)) == Value.float(2.71)
    end

    test "negate returns error for text" do
      result = Value.negate(Value.text("hello"))
      assert {:error, _reason} = result
    end

    test "negate! raises error for text" do
      assert_raise RuntimeError, fn ->
        Value.negate!(Value.text("hello"))
      end
    end

    test "negate returns error for list" do
      result = Value.negate(Value.list([Value.integer(1)]))
      assert {:error, _reason} = result
    end

    test "negate! raises error for list" do
      assert_raise RuntimeError, fn ->
        Value.negate!(Value.list([Value.integer(1)]))
      end
    end
  end
end
