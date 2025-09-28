defmodule Scrapex.Evaluator.Rock.Conversion.ToTextTest do
  use ExUnit.Case

  alias Scrapex.{Evaluator.Rock, Value}

  describe "$$to_text" do
    test "converts integer to text" do
      result = Rock.apply_native_function("to_text", Value.integer(42))
      assert result == {:ok, Value.text("42")}
    end

    test "converts negative integer to text" do
      result = Rock.apply_native_function("to_text", Value.integer(-123))
      assert result == {:ok, Value.text("-123")}
    end

    test "converts zero to text" do
      result = Rock.apply_native_function("to_text", Value.integer(0))
      assert result == {:ok, Value.text("0")}
    end

    test "converts large integer to text" do
      result = Rock.apply_native_function("to_text", Value.integer(999_999_999))
      assert result == {:ok, Value.text("999999999")}
    end

    test "converts float to text" do
      result = Rock.apply_native_function("to_text", Value.float(3.14))
      assert result == {:ok, Value.text("3.14")}
    end

    test "converts negative float to text" do
      result = Rock.apply_native_function("to_text", Value.float(-2.5))
      assert result == {:ok, Value.text("-2.5")}
    end

    test "converts zero float to text" do
      result = Rock.apply_native_function("to_text", Value.float(0.0))
      assert result == {:ok, Value.text("0.0")}
    end

    test "converts very small float to text" do
      result = Rock.apply_native_function("to_text", Value.float(0.001))
      assert result == {:ok, Value.text("0.001")}
    end

    test "converts hexbyte to text" do
      result = Rock.apply_native_function("to_text", Value.hexbyte(255))
      assert result == {:ok, Value.text("~FF")}
    end

    test "converts small hexbyte to text" do
      result = Rock.apply_native_function("to_text", Value.hexbyte(15))
      assert result == {:ok, Value.text("~0F")}
    end

    test "converts zero hexbyte to text" do
      result = Rock.apply_native_function("to_text", Value.hexbyte(0))
      assert result == {:ok, Value.text("~00")}
    end

    test "converts base64 to text" do
      result = Rock.apply_native_function("to_text", Value.base64("SGVsbG8="))
      assert result == {:ok, Value.text("SGVsbG8=")}
    end

    test "converts empty base64 to text" do
      result = Rock.apply_native_function("to_text", Value.base64(""))
      assert result == {:ok, Value.text("")}
    end

    test "returns error for unsupported types" do
      unsupported_values = [
        Value.list([Value.integer(1)]),
        Value.record([{"key", Value.text("value")}]),
        Value.variant("ok"),
        Value.hole()
      ]

      for value <- unsupported_values do
        result = Rock.apply_native_function("to_text", value)
        assert {:error, _reason} = result
      end
    end
  end
end
