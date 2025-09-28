defmodule Scrapex.Evaluator.Rock.KeysTest do
  use ExUnit.Case

  alias Scrapex.{Evaluator.Rock, Value}

  describe "$$keys" do
    test "keys of record with multiple fields" do
      record_value = Value.record([{"name", Value.text("Alice")}, {"age", Value.integer(30)}])
      result = Rock.apply_native_function("keys", record_value)

      expected = Value.list([Value.text("name"), Value.text("age")])
      assert result == {:ok, expected}
    end

    test "keys of empty record" do
      result = Rock.apply_native_function("keys", Value.record([]))
      assert result == {:ok, Value.list([])}
    end

    test "keys of single field record" do
      record_value = Value.record([{"id", Value.integer(123)}])
      result = Rock.apply_native_function("keys", record_value)

      expected = Value.list([Value.text("id")])
      assert result == {:ok, expected}
    end

    test "keys preserves field order" do
      record_value =
        Value.record([
          {"z", Value.integer(1)},
          {"a", Value.integer(2)},
          {"m", Value.integer(3)}
        ])

      result = Rock.apply_native_function("keys", record_value)

      expected = Value.list([Value.text("z"), Value.text("a"), Value.text("m")])
      assert result == {:ok, expected}
    end

    test "keys with different value types" do
      record_value =
        Value.record([
          {"text_field", Value.text("hello")},
          {"int_field", Value.integer(42)},
          {"list_field", Value.list([Value.integer(1)])},
          {"variant_field", Value.variant("ok")}
        ])

      result = Rock.apply_native_function("keys", record_value)

      expected =
        Value.list([
          Value.text("text_field"),
          Value.text("int_field"),
          Value.text("list_field"),
          Value.text("variant_field")
        ])

      assert result == {:ok, expected}
    end

    test "keys with complex field names" do
      record_value =
        Value.record([
          {"field_with_underscores", Value.integer(1)},
          {"field-with-dashes", Value.integer(2)},
          {"123numeric", Value.integer(3)}
        ])

      result = Rock.apply_native_function("keys", record_value)

      expected =
        Value.list([
          Value.text("field_with_underscores"),
          Value.text("field-with-dashes"),
          Value.text("123numeric")
        ])

      assert result == {:ok, expected}
    end

    test "returns error for non-record types" do
      non_record_values = [
        Value.integer(42),
        Value.float(3.14),
        Value.text("hello"),
        Value.list([Value.integer(1)]),
        Value.variant("ok"),
        Value.hole(),
        Value.hexbyte(255),
        Value.base64("SGVsbG8=")
      ]

      for value <- non_record_values do
        result = Rock.apply_native_function("keys", value)
        assert {:error, _reason} = result
      end
    end
  end
end
