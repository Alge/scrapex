defmodule Scrapex.Evaluator.Rock.Conversion.ToFloatTest do
  use ExUnit.Case

  alias Scrapex.{Evaluator.Rock, Value}

  describe "$$to_float" do
    test "converts text to float" do
      result = Rock.apply_native_function("to_float", Value.text("3.14"))
      assert result == {:ok, Value.float(3.14)}
    end

    test "converts integer text to float" do
      result = Rock.apply_native_function("to_float", Value.text("42"))
      assert result == {:ok, Value.float(42.0)}
    end

    test "converts negative text to float" do
      result = Rock.apply_native_function("to_float", Value.text("-2.5"))
      assert result == {:ok, Value.float(-2.5)}
    end

    test "converts zero text to float" do
      result = Rock.apply_native_function("to_float", Value.text("0"))
      assert result == {:ok, Value.float(0.0)}
    end

    test "returns error for invalid text" do
      invalid_texts = ["hello", "f3.14abc", "abc3.14", "", "  3.14  "]

      for text <- invalid_texts do
        result = Rock.apply_native_function("to_float", Value.text(text))
        assert {:error, reason} = result
        assert String.contains?(reason, "Cannot convert")
      end
    end

    test "converts integer to float" do
      result = Rock.apply_native_function("to_float", Value.integer(42))
      assert result == {:ok, Value.float(42.0)}
    end

    test "converts negative integer to float" do
      result = Rock.apply_native_function("to_float", Value.integer(-5))
      assert result == {:ok, Value.float(-5.0)}
    end

    test "converts zero integer to float" do
      result = Rock.apply_native_function("to_float", Value.integer(0))
      assert result == {:ok, Value.float(0.0)}
    end

    test "converts hexbyte to float" do
      result = Rock.apply_native_function("to_float", Value.hexbyte(128))
      assert result == {:ok, Value.float(128.0)}
    end

    test "converts zero hexbyte to float" do
      result = Rock.apply_native_function("to_float", Value.hexbyte(0))
      assert result == {:ok, Value.float(0.0)}
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
        result = Rock.apply_native_function("to_float", value)
        assert {:error, _reason} = result
      end
    end
  end
end
