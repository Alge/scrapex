defmodule Scrapex.Value.Base64Test do
  use ExUnit.Case

  alias Scrapex.Value

  describe "base64 values" do
    test "create base64 value from base64 string" do
      # "Hello" in base64
      base64_string = "SGVsbG8="
      assert Value.base64(base64_string) == {:base64, base64_string}
    end

    test "create base64 value from empty string" do
      assert Value.base64("") == {:base64, ""}
    end

    test "display base64 value" do
      base64_value = Value.base64("SGVsbG8=")
      result = Value.display(base64_value)
      assert result == {:ok, "~~SGVsbG8="}
    end

    test "display! base64 value" do
      base64_value = Value.base64("AQIDBA==")
      assert Value.display!(base64_value) == "~~AQIDBA=="
    end

    test "display empty base64" do
      base64_value = Value.base64("")
      assert Value.display!(base64_value) == "~~"
    end

    test "base64 values are equal when same string" do
      base64_1 = Value.base64("SGVsbG8=")
      base64_2 = Value.base64("SGVsbG8=")
      result = Value.equal(base64_1, base64_2)
      assert result == {:ok, Value.variant("true")}
    end

    test "base64 values are not equal when different strings" do
      base64_1 = Value.base64("AQIDBA==")
      base64_2 = Value.base64("BQYHCA==")
      result = Value.equal(base64_1, base64_2)
      assert result == {:ok, Value.variant("false")}
    end

    test "base64 values are not equal to other types" do
      base64_value = Value.base64("SGVsbG8=")
      text_value = Value.text("SGVsbG8=")
      result = Value.equal(base64_value, text_value)
      assert {:error, _reason} = result
    end

    test "base64 inequality comparison" do
      base64_1 = Value.base64("AQIDBA==")
      base64_2 = Value.base64("BQYHCA==")
      result = Value.not_equal(base64_1, base64_2)
      assert result == {:ok, Value.variant("true")}
    end

    test "base64 values cannot be negated" do
      base64_value = Value.base64("SGVsbG8=")
      result = Value.negate(base64_value)
      assert {:error, _reason} = result
    end

    test "base64 values cannot be added" do
      base64_1 = Value.base64("AQIDBA==")
      base64_2 = Value.base64("BQYHCA==")
      result = Value.add(base64_1, base64_2)
      assert {:error, _reason} = result
    end

    test "base64 values cannot be subtracted" do
      base64_1 = Value.base64("AQIDBA==")
      base64_2 = Value.base64("BQYHCA==")
      result = Value.subtract(base64_1, base64_2)
      assert {:error, _reason} = result
    end

    test "base64 values cannot be compared with less than" do
      base64_1 = Value.base64("AQIDBA==")
      base64_2 = Value.base64("BQYHCA==")
      result = Value.less_than(base64_1, base64_2)
      assert {:error, _reason} = result
    end

    test "base64 values cannot be compared with greater than" do
      base64_1 = Value.base64("BQYHCA==")
      base64_2 = Value.base64("AQIDBA==")
      result = Value.greater_than(base64_1, base64_2)
      assert {:error, _reason} = result
    end

    test "base64 values can be stored in lists" do
      base64_1 = Value.base64("AQID")
      base64_2 = Value.base64("BAUG")
      list_value = Value.list([base64_1, base64_2])

      assert Value.display!(list_value) == "[~~AQID, ~~BAUG]"
    end

    test "base64 values can be stored in records" do
      base64_value = Value.base64("/v/9")
      record_value = Value.record([{"data", base64_value}, {"size", Value.integer(3)}])

      assert Value.display!(record_value) == "{data: ~~\/v\/9, size: 3}"
    end

    test "base64 values can be consed to lists" do
      base64_value = Value.base64("AQID")
      list_value = Value.list([Value.base64("BAUG")])
      result = Value.cons(base64_value, list_value)
      expected = Value.list([Value.base64("AQID"), Value.base64("BAUG")])
      assert result == {:ok, expected}
    end

    test "base64 values can be appended to lists" do
      base64_value = Value.base64("AQID")
      list_value = Value.list([Value.base64("BAUG")])
      result = Value.append_to_list(list_value, base64_value)
      expected = Value.list([Value.base64("BAUG"), Value.base64("AQID")])
      assert result == {:ok, expected}
    end

    test "base64 values cannot be appended to text" do
      base64_value = Value.base64("AQID")
      text_value = Value.text("data: ")
      result = Value.append_text(text_value, base64_value)
      assert {:error, _reason} = result
    end

    test "base64 creation validates base64 format" do
      # Valid base64 strings
      assert Value.base64("SGVsbG8=") == {:base64, "SGVsbG8="}
      assert Value.base64("AQIDBA==") == {:base64, "AQIDBA=="}
      # Properly padded
      assert Value.base64("YWJjZA==") == {:base64, "YWJjZA=="}

      # Invalid base64 strings should raise errors
      assert_raise ArgumentError, fn ->
        # Invalid characters
        Value.base64("invalid!@#")
      end

      assert_raise ArgumentError, fn ->
        # Invalid padding - should be SGVsbG8=
        Value.base64("SGVsbG8")
      end
    end

    test "base64 with various padding scenarios" do
      # Different valid padding patterns
      valid_strings = [
        # 1 padding char
        "SGVsbG8=",
        # 2 padding chars
        "SGVsbG9Xbw==",
        # 2 padding chars (was missing ==)
        "YWJjZA==",
        # Short string with padding
        "QQ=="
      ]

      Enum.each(valid_strings, fn base64_str ->
        base64_value = Value.base64(base64_str)
        assert base64_value == {:base64, base64_str}
        assert Value.display!(base64_value) == "~~" <> base64_str
      end)
    end

    test "base64 preserves original string format" do
      original = "SGVsbG8="
      base64_value = Value.base64(original)

      # Should store exactly what was provided
      assert base64_value == {:base64, original}

      # Display should show exactly what was stored
      assert Value.display!(base64_value) == "~~" <> original
    end
  end
end
