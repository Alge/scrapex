defmodule Scrapex.Value.HexbyteTest do
  use ExUnit.Case

  alias Scrapex.Value

  describe "hexbyte values" do
    test "create hexbyte value" do
      assert Value.hexbyte(255) == {:hexbyte, 255}
    end

    test "create hexbyte from hex string" do
      assert Value.hexbyte("FF") == {:hexbyte, 255}
      assert Value.hexbyte("A0") == {:hexbyte, 160}
      assert Value.hexbyte("00") == {:hexbyte, 0}
    end

    test "display hexbyte value" do
      hexbyte_value = Value.hexbyte(255)
      assert Value.display(hexbyte_value) == {:ok, "~FF"}
    end

    test "display! hexbyte value" do
      hexbyte_value = Value.hexbyte(160)
      assert Value.display!(hexbyte_value) == "~A0"
    end

    test "display hexbyte with single digit" do
      hexbyte_value = Value.hexbyte(15)
      assert Value.display!(hexbyte_value) == "~0F"
    end

    test "display hexbyte zero" do
      hexbyte_value = Value.hexbyte(0)
      assert Value.display!(hexbyte_value) == "~00"
    end

    test "hexbyte values are equal when same value" do
      hex1 = Value.hexbyte(255)
      hex2 = Value.hexbyte(255)
      result = Value.equal(hex1, hex2)
      assert result == {:ok, Value.variant("true")}
    end

    test "hexbyte values are not equal when different values" do
      hex1 = Value.hexbyte(255)
      hex2 = Value.hexbyte(128)
      result = Value.equal(hex1, hex2)
      assert result == {:ok, Value.variant("false")}
    end

    test "hexbyte values are not equal to other types" do
      hexbyte_value = Value.hexbyte(42)
      integer_value = Value.integer(42)
      result = Value.equal(hexbyte_value, integer_value)
      assert {:error, _reason} = result
    end

    test "hexbyte inequality comparison" do
      hex1 = Value.hexbyte(255)
      hex2 = Value.hexbyte(128)
      result = Value.not_equal(hex1, hex2)
      assert result == {:ok, Value.variant("true")}
    end

    test "hexbyte values cannot be negated" do
      hexbyte_value = Value.hexbyte(255)
      result = Value.negate(hexbyte_value)
      assert {:error, _reason} = result
    end

    test "hexbyte values cannot be added" do
      hex1 = Value.hexbyte(255)
      hex2 = Value.hexbyte(128)
      result = Value.add(hex1, hex2)
      assert {:error, _reason} = result
    end

    test "hexbyte values cannot be subtracted" do
      hex1 = Value.hexbyte(255)
      hex2 = Value.hexbyte(128)
      result = Value.subtract(hex1, hex2)
      assert {:error, _reason} = result
    end

    test "hexbyte values cannot be multiplied" do
      hex1 = Value.hexbyte(255)
      integer_value = Value.integer(2)
      result = Value.multiply(hex1, integer_value)
      assert {:error, _reason} = result
    end

    test "hexbyte values cannot be divided" do
      hex1 = Value.hexbyte(255)
      integer_value = Value.integer(2)
      result = Value.divide(hex1, integer_value)
      assert {:error, _reason} = result
    end

    test "hexbyte values can be compared with less than" do
      hex1 = Value.hexbyte(128)
      hex2 = Value.hexbyte(255)
      result = Value.less_than(hex1, hex2)
      assert result == {:ok, Value.variant("true")}
    end

    test "hexbyte values can be compared with greater than" do
      hex1 = Value.hexbyte(255)
      hex2 = Value.hexbyte(128)
      result = Value.greater_than(hex1, hex2)
      assert result == {:ok, Value.variant("true")}
    end

    test "hexbyte equality in ordering" do
      hex1 = Value.hexbyte(128)
      hex2 = Value.hexbyte(128)
      assert Value.less_than(hex1, hex2) == {:ok, Value.variant("false")}
      assert Value.greater_than(hex1, hex2) == {:ok, Value.variant("false")}
    end

    test "hexbyte values can be stored in lists" do
      hex1 = Value.hexbyte(255)
      hex2 = Value.hexbyte(128)
      list_value = Value.list([hex1, hex2, Value.hexbyte(0)])
      expected_display = "[~FF, ~80, ~00]"
      assert Value.display!(list_value) == expected_display
    end

    test "hexbyte values can be stored in records" do
      hex_value = Value.hexbyte(255)
      record_value = Value.record([{"data", hex_value}, {"size", Value.integer(1)}])
      expected_display = "{data: ~FF, size: 1}"
      assert Value.display!(record_value) == expected_display
    end

    test "hexbyte values can be consed to lists" do
      hex_value = Value.hexbyte(255)
      list_value = Value.list([Value.hexbyte(128)])
      result = Value.cons(hex_value, list_value)
      expected = Value.list([Value.hexbyte(255), Value.hexbyte(128)])
      assert result == {:ok, expected}
    end

    test "hexbyte values can be appended to lists" do
      hex_value = Value.hexbyte(255)
      list_value = Value.list([Value.hexbyte(128)])
      result = Value.append_to_list(list_value, hex_value)
      expected = Value.list([Value.hexbyte(128), Value.hexbyte(255)])
      assert result == {:ok, expected}
    end

    test "hexbyte values cannot be appended to text" do
      hex_value = Value.hexbyte(255)
      text_value = Value.text("data: ")
      result = Value.append_text(text_value, hex_value)
      assert {:error, _reason} = result
    end

    test "hexbyte boundary values" do
      min_hex = Value.hexbyte(0)
      max_hex = Value.hexbyte(255)
      assert Value.display!(min_hex) == "~00"
      assert Value.display!(max_hex) == "~FF"
    end

    test "hexbyte creation should validate range" do
      # Test that values outside 0-255 raise errors
      assert_raise ArgumentError, fn ->
        Value.hexbyte(256)
      end

      assert_raise ArgumentError, fn ->
        Value.hexbyte(-1)
      end
    end

    test "hexbyte creation from invalid hex string" do
      assert_raise ArgumentError, fn ->
        # Invalid hex characters
        Value.hexbyte("GG")
      end

      assert_raise ArgumentError, fn ->
        # Too long
        Value.hexbyte("FFF")
      end

      assert_raise ArgumentError, fn ->
        # Empty string
        Value.hexbyte("")
      end
    end
  end
end
