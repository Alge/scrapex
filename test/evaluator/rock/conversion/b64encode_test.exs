defmodule Scrapex.Evaluator.Rock.B64EncodeTest do
  use ExUnit.Case

  alias Scrapex.{Evaluator.Rock, Value}

  describe "$$b64encode" do
    test "encodes text to base64" do
      result = Rock.apply_native_function("b64encode", Value.text("Hello"))
      assert result == {:ok, Value.base64("SGVsbG8=")}
    end

    test "encodes empty text" do
      result = Rock.apply_native_function("b64encode", Value.text(""))
      assert result == {:ok, Value.base64("")}
    end

    test "encodes single character" do
      result = Rock.apply_native_function("b64encode", Value.text("A"))
      assert result == {:ok, Value.base64("QQ==")}
    end

    test "encodes text with special characters" do
      result = Rock.apply_native_function("b64encode", Value.text("Hello, World!"))
      assert result == {:ok, Value.base64("SGVsbG8sIFdvcmxkIQ==")}
    end

    test "encodes unicode text" do
      result = Rock.apply_native_function("b64encode", Value.text("🚀🌟"))
      # Unicode rocket and star emojis should encode successfully
      assert {:ok, encoded_value} = result
      assert match?({:base64, _}, encoded_value)
    end

    test "encodes text with newlines" do
      result = Rock.apply_native_function("b64encode", Value.text("line1\nline2"))
      assert {:ok, encoded_value} = result
      assert match?({:base64, _}, encoded_value)
    end

    test "encodes binary-like text" do
      # Text that looks like binary data
      result = Rock.apply_native_function("b64encode", Value.text("\x00\x01\x02\x03"))
      assert {:ok, encoded_value} = result
      assert match?({:base64, _}, encoded_value)
    end

    test "known encoding examples" do
      test_cases = [
        {"Hello", "SGVsbG8="},
        {"Hi", "SGk="},
        {"Hel", "SGVs"},
        {"A", "QQ=="},
        {"", ""}
      ]

      for {input, expected_output} <- test_cases do
        result = Rock.apply_native_function("b64encode", Value.text(input))
        assert result == {:ok, Value.base64(expected_output)}
      end
    end

    test "returns error for non-text types" do
      non_text_values = [
        Value.integer(42),
        Value.float(3.14),
        Value.list([Value.text("hello")]),
        Value.record([{"key", Value.text("value")}]),
        Value.variant("ok"),
        Value.hole(),
        Value.hexbyte(255),
        Value.base64("SGVsbG8=")
      ]

      for value <- non_text_values do
        result = Rock.apply_native_function("b64encode", value)
        assert {:error, _reason} = result
      end
    end
  end
end
