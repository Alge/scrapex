defmodule Scrapex.Evaluator.Rock.B64DecodeTest do
  use ExUnit.Case

  alias Scrapex.{Evaluator.Rock, Value}

  describe "$$b64decode" do
    test "decodes base64 to text" do
      result = Rock.apply_native_function("b64decode", Value.base64("SGVsbG8="))
      assert result == {:ok, Value.text("Hello")}
    end

    test "decodes empty base64" do
      result = Rock.apply_native_function("b64decode", Value.base64(""))
      assert result == {:ok, Value.text("")}
    end

    test "decodes single character base64" do
      result = Rock.apply_native_function("b64decode", Value.base64("QQ=="))
      assert result == {:ok, Value.text("A")}
    end

    test "decodes base64 with special characters" do
      result = Rock.apply_native_function("b64decode", Value.base64("SGVsbG8sIFdvcmxkIQ=="))
      assert result == {:ok, Value.text("Hello, World!")}
    end

    test "decodes base64 with different padding" do
      # Test different padding scenarios
      test_cases = [
        # 2 padding chars
        {"QQ==", "A"},
        # 1 padding char
        {"SGk=", "Hi"},
        # No padding needed
        {"SGVs", "Hel"}
      ]

      for {base64_input, expected_text} <- test_cases do
        result = Rock.apply_native_function("b64decode", Value.base64(base64_input))
        assert result == {:ok, Value.text(expected_text)}
      end
    end

    test "handles roundtrip encoding/decoding" do
      original_texts = [
        "Hello, World!",
        "ScrapScript rocks!",
        "Multi\nline\ntext",
        ""
      ]

      for original <- original_texts do
        # Encode then decode should return original
        encoded_result = Rock.apply_native_function("b64encode", Value.text(original))
        assert {:ok, encoded_base64} = encoded_result

        decoded_result = Rock.apply_native_function("b64decode", encoded_base64)
        assert decoded_result == {:ok, Value.text(original)}
      end
    end

    test "handles unicode roundtrip" do
      unicode_text = "🚀 Unicode test 🌟"

      encoded_result = Rock.apply_native_function("b64encode", Value.text(unicode_text))
      assert {:ok, encoded_base64} = encoded_result

      decoded_result = Rock.apply_native_function("b64decode", encoded_base64)
      assert decoded_result == {:ok, Value.text(unicode_text)}
    end

    test "returns error for invalid base64" do
      invalid_base64_values = [
        # Invalid characters
        {:base64, "invalid!@#"},
        # Invalid padding
        {:base64, "SGVsbG8"},
        # Wrong padding
        {:base64, "SGVs="},
        # Too short
        {:base64, "A"}
      ]

      for invalid_b64_value <- invalid_base64_values do
        result = Rock.apply_native_function("b64decode", invalid_b64_value)
        assert {:error, reason} = result
        assert String.contains?(reason, "Invalid base64")
      end
    end

    test "returns error for non-base64 types" do
      non_base64_values = [
        Value.integer(42),
        Value.float(3.14),
        Value.text("hello"),
        Value.list([Value.text("hello")]),
        Value.record([{"key", Value.text("value")}]),
        Value.variant("ok"),
        Value.hole(),
        Value.hexbyte(255)
      ]

      for value <- non_base64_values do
        result = Rock.apply_native_function("b64decode", value)
        assert {:error, _reason} = result
      end
    end

    test "handles binary data correctly" do
      # Test with data that contains null bytes and other binary content
      binary_text = "\x00\x01\x02\x03\xFF\xFE"

      # Encode to base64
      encode_result = Rock.apply_native_function("b64encode", Value.text(binary_text))
      assert {:ok, encoded_base64} = encode_result

      # Decode back
      decode_result = Rock.apply_native_function("b64decode", encoded_base64)
      assert decode_result == {:ok, Value.text(binary_text)}
    end

    test "known decoding examples" do
      test_cases = [
        {"SGVsbG8=", "Hello"},
        {"SGk=", "Hi"},
        {"SGVs", "Hel"},
        {"QQ==", "A"},
        {"", ""}
      ]

      for {base64_input, expected_text} <- test_cases do
        result = Rock.apply_native_function("b64decode", Value.base64(base64_input))
        assert result == {:ok, Value.text(expected_text)}
      end
    end
  end
end
