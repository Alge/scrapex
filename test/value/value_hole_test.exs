defmodule Scrapex.Value.HoleTest do
  use ExUnit.Case

  alias Scrapex.Value

  describe "hole values" do
    test "create hole value" do
      assert Value.hole() == {:hole}
    end

    test "display hole value" do
      hole_value = Value.hole()
      assert Value.display(hole_value) == {:ok, "()"}
    end

    test "display! hole value" do
      hole_value = Value.hole()
      assert Value.display!(hole_value) == "()"
    end

    test "hole values are equal to each other" do
      hole1 = Value.hole()
      hole2 = Value.hole()
      result = Value.equal(hole1, hole2)
      assert result == {:ok, Value.variant("true")}
    end

    test "hole values are not equal to other types" do
      hole_value = Value.hole()
      integer_value = Value.integer(42)
      result = Value.equal(hole_value, integer_value)
      assert {:error, _reason} = result
    end

    test "hole values cannot be negated" do
      hole_value = Value.hole()
      result = Value.negate(hole_value)
      assert {:error, _reason} = result
    end

    test "hole values cannot be added" do
      hole_value = Value.hole()
      integer_value = Value.integer(5)
      result = Value.add(hole_value, integer_value)
      assert {:error, _reason} = result
    end

    test "hole values cannot be subtracted" do
      hole_value = Value.hole()
      integer_value = Value.integer(3)
      result = Value.subtract(hole_value, integer_value)
      assert {:error, _reason} = result
    end

    test "hole values cannot be multiplied" do
      hole_value = Value.hole()
      integer_value = Value.integer(2)
      result = Value.multiply(hole_value, integer_value)
      assert {:error, _reason} = result
    end

    test "hole values cannot be divided" do
      hole_value = Value.hole()
      integer_value = Value.integer(4)
      result = Value.divide(hole_value, integer_value)
      assert {:error, _reason} = result
    end

    test "hole values cannot be appended to text" do
      hole_value = Value.hole()
      text_value = Value.text("hello")
      result = Value.append_text(text_value, hole_value)
      assert {:error, _reason} = result
    end

    test "hole values can be consed to lists" do
      hole_value = Value.hole()
      list_value = Value.list([Value.integer(1)])
      result = Value.cons(hole_value, list_value)
      assert result == {:ok, Value.list([Value.hole(), Value.integer(1)])}
    end

    test "hole values cannot be appended to lists" do
      hole_value = Value.hole()
      list_value = Value.list([Value.integer(1)])
      result = Value.append_to_list(list_value, hole_value)
      # This should succeed - holes can be list elements
      assert result == {:ok, Value.list([Value.integer(1), Value.hole()])}
    end

    test "lists can contain hole values" do
      hole_value = Value.hole()
      list_value = Value.list([Value.integer(1), hole_value, Value.integer(3)])
      expected_display = "[1, (), 3]"
      assert Value.display!(list_value) == expected_display
    end

    test "records can contain hole values" do
      hole_value = Value.hole()
      record_value = Value.record([{"missing", hole_value}, {"present", Value.integer(42)}])
      expected_display = "{missing: (), present: 42}"
      assert Value.display!(record_value) == expected_display
    end

    test "hole values cannot be compared with less than" do
      hole1 = Value.hole()
      hole2 = Value.hole()
      result = Value.less_than(hole1, hole2)
      assert {:error, _reason} = result
    end

    test "hole values cannot be compared with greater than" do
      hole_value = Value.hole()
      integer_value = Value.integer(5)
      result = Value.greater_than(hole_value, integer_value)
      assert {:error, _reason} = result
    end

    test "hole values can be not equal to other types" do
      hole_value = Value.hole()
      text_value = Value.text("hello")
      result = Value.not_equal(hole_value, text_value)
      assert {:error, _reason} = result
    end

    test "hole values are not equal when compared to themselves with not_equal" do
      hole1 = Value.hole()
      hole2 = Value.hole()
      result = Value.not_equal(hole1, hole2)
      assert result == {:ok, Value.variant("false")}
    end

    test "multiple hole values in complex structures" do
      hole_value = Value.hole()

      complex_list =
        Value.list([
          Value.record([{"data", hole_value}]),
          Value.list([hole_value, hole_value]),
          hole_value
        ])

      expected_display = "[{data: ()}, [(), ()], ()]"
      assert Value.display!(complex_list) == expected_display
    end
  end
end
