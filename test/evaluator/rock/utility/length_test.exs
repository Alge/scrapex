defmodule Scrapex.Evaluator.Rock.Utility.LengthTest do
  use ExUnit.Case

  alias Scrapex.{Evaluator.Rock, Value}

  describe "$$length" do
    test "length of list with multiple elements" do
      list_value = Value.list([Value.integer(1), Value.integer(2), Value.integer(3)])
      result = Rock.apply_native_function("length", list_value)
      assert result == {:ok, Value.integer(3)}
    end

    test "length of empty list" do
      result = Rock.apply_native_function("length", Value.list([]))
      assert result == {:ok, Value.integer(0)}
    end

    test "length of single element list" do
      list_value = Value.list([Value.text("only")])
      result = Rock.apply_native_function("length", list_value)
      assert result == {:ok, Value.integer(1)}
    end

    test "length of text" do
      result = Rock.apply_native_function("length", Value.text("hello"))
      assert result == {:ok, Value.integer(5)}
    end

    test "length of empty text" do
      result = Rock.apply_native_function("length", Value.text(""))
      assert result == {:ok, Value.integer(0)}
    end

    test "length of single character text" do
      result = Rock.apply_native_function("length", Value.text("a"))
      assert result == {:ok, Value.integer(1)}
    end

    test "length of unicode text" do
      result = Rock.apply_native_function("length", Value.text("🚀🌟"))
      assert result == {:ok, Value.integer(2)}
    end

    test "returns error for unsupported types" do
      unsupported_values = [
        Value.integer(42),
        Value.float(3.14),
        Value.record([{"key", Value.text("value")}]),
        Value.variant("ok"),
        Value.hole(),
        Value.hexbyte(255),
        Value.base64("SGVsbG8=")
      ]

      for value <- unsupported_values do
        result = Rock.apply_native_function("length", value)
        assert {:error, _reason} = result
      end
    end
  end
end
