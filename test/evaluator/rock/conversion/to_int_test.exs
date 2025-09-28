defmodule Scrapex.Evaluator.Rock.Conversion.ToIntTest do
  use ExUnit.Case

  alias Scrapex.{Evaluator.Rock, Value}

  describe "$$to_int" do
    test "converts text to integer" do
      result = Rock.apply_native_function("to_int", Value.text("42"))
      assert result == {:ok, Value.integer(42)}
    end

    test "converts negative text to integer" do
      result = Rock.apply_native_function("to_int", Value.text("-123"))
      assert result == {:ok, Value.integer(-123)}
    end

    test "converts zero text to integer" do
      result = Rock.apply_native_function("to_int", Value.text("0"))
      assert result == {:ok, Value.integer(0)}
    end

    test "returns error for invalid text" do
      invalid_texts = ["hello", "a42abc", "abc42", "", "  42  "]

      for text <- invalid_texts do
        result = Rock.apply_native_function("to_int", Value.text(text))
        assert {:error, reason} = result
        assert String.contains?(reason, "Cannot convert")
      end
    end

    test "converts float to integer (truncated)" do
      result = Rock.apply_native_function("to_int", Value.float(3.14))
      assert result == {:ok, Value.integer(3)}
    end

    test "converts negative float to integer" do
      result = Rock.apply_native_function("to_int", Value.float(-2.8))
      assert result == {:ok, Value.integer(-2)}
    end

    test "converts zero float to integer" do
      result = Rock.apply_native_function("to_int", Value.float(0.0))
      assert result == {:ok, Value.integer(0)}
    end

    test "converts hexbyte to integer" do
      result = Rock.apply_native_function("to_int", Value.hexbyte(255))
      assert result == {:ok, Value.integer(255)}
    end

    test "converts small hexbyte to integer" do
      result = Rock.apply_native_function("to_int", Value.hexbyte(15))
      assert result == {:ok, Value.integer(15)}
    end

    test "converts zero hexbyte to integer" do
      result = Rock.apply_native_function("to_int", Value.hexbyte(0))
      assert result == {:ok, Value.integer(0)}
    end

    test "returns error for unsupported types" do
      unsupported_values = [
        Value.list([Value.integer(1)]),
        Value.record([{"key", Value.text("value")}]),
        Value.variant("ok"),
        Value.hole(),
        Value.base64("SGVsbG8=")
      ]

      for value <- unsupported_values do
        result = Rock.apply_native_function("to_int", value)
        assert {:error, _reason} = result
      end
    end
  end
end
