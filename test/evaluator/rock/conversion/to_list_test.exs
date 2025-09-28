defmodule Scrapex.Evaluator.Rock.ToListTest do
  use ExUnit.Case

  alias Scrapex.{Evaluator.Rock, Value}

  describe "$$to_list" do
    test "converts text to character list" do
      result = Rock.apply_native_function("to_list", Value.text("hello"))

      expected =
        Value.list([
          Value.text("h"),
          Value.text("e"),
          Value.text("l"),
          Value.text("l"),
          Value.text("o")
        ])

      assert result == {:ok, expected}
    end

    test "converts empty text to empty list" do
      result = Rock.apply_native_function("to_list", Value.text(""))
      assert result == {:ok, Value.list([])}
    end

    test "converts single character text" do
      result = Rock.apply_native_function("to_list", Value.text("A"))
      expected = Value.list([Value.text("A")])
      assert result == {:ok, expected}
    end

    test "converts text with spaces" do
      result = Rock.apply_native_function("to_list", Value.text("a b"))

      expected =
        Value.list([
          Value.text("a"),
          Value.text(" "),
          Value.text("b")
        ])

      assert result == {:ok, expected}
    end

    test "converts text with special characters" do
      result = Rock.apply_native_function("to_list", Value.text("a!@#"))

      expected =
        Value.list([
          Value.text("a"),
          Value.text("!"),
          Value.text("@"),
          Value.text("#")
        ])

      assert result == {:ok, expected}
    end

    test "converts text with unicode characters" do
      result = Rock.apply_native_function("to_list", Value.text("🚀🌟"))

      expected =
        Value.list([
          Value.text("🚀"),
          Value.text("🌟")
        ])

      assert result == {:ok, expected}
    end

    test "converts text with newlines and tabs" do
      result = Rock.apply_native_function("to_list", Value.text("a\nb\tc"))

      expected =
        Value.list([
          Value.text("a"),
          Value.text("\n"),
          Value.text("b"),
          Value.text("\t"),
          Value.text("c")
        ])

      assert result == {:ok, expected}
    end

    test "converts text with numbers" do
      result = Rock.apply_native_function("to_list", Value.text("123"))

      expected =
        Value.list([
          Value.text("1"),
          Value.text("2"),
          Value.text("3")
        ])

      assert result == {:ok, expected}
    end

    test "converts mixed alphanumeric text" do
      result = Rock.apply_native_function("to_list", Value.text("a1b2"))

      expected =
        Value.list([
          Value.text("a"),
          Value.text("1"),
          Value.text("b"),
          Value.text("2")
        ])

      assert result == {:ok, expected}
    end

    test "preserves character order" do
      result = Rock.apply_native_function("to_list", Value.text("dcba"))

      expected =
        Value.list([
          Value.text("d"),
          Value.text("c"),
          Value.text("b"),
          Value.text("a")
        ])

      assert result == {:ok, expected}
    end

    test "handles repeated characters" do
      result = Rock.apply_native_function("to_list", Value.text("aaa"))

      expected =
        Value.list([
          Value.text("a"),
          Value.text("a"),
          Value.text("a")
        ])

      assert result == {:ok, expected}
    end

    test "returns error for non-text types" do
      non_text_values = [
        Value.integer(42),
        Value.float(3.14),
        Value.list([Value.text("a")]),
        Value.record([{"key", Value.text("value")}]),
        Value.variant("ok"),
        Value.hole(),
        Value.hexbyte(255),
        Value.base64("SGVsbG8=")
      ]

      for value <- non_text_values do
        result = Rock.apply_native_function("to_list", value)
        assert {:error, _reason} = result
      end
    end
  end
end
