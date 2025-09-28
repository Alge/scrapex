defmodule Scrapex.Value.RecordTest do
  use ExUnit.Case

  alias Scrapex.Value

  describe "record values" do
    test "create record value" do
      fields = [{"name", Value.text("Alice")}, {"age", Value.integer(30)}]
      assert Value.record(fields) == {:record, fields}
    end

    test "display empty record" do
      record_value = Value.record([])
      assert Value.display(record_value) == {:ok, "{}"}
    end

    test "display record with one field" do
      fields = [{"name", Value.text("Bob")}]
      record_value = Value.record(fields)
      assert Value.display(record_value) == {:ok, "{name: \"Bob\"}"}
    end

    test "display record with multiple fields" do
      fields = [{"name", Value.text("Alice")}, {"age", Value.integer(30)}]
      record_value = Value.record(fields)
      assert Value.display(record_value) == {:ok, "{name: \"Alice\", age: 30}"}
    end

    test "display! record" do
      fields = [{"x", Value.integer(1)}]
      record_value = Value.record(fields)
      assert Value.display!(record_value) == "{x: 1}"
    end

    test "negate returns error for record" do
      record_value = Value.record([])
      result = Value.negate(record_value)
      assert {:error, _reason} = result
    end

    test "negate! raises error for record" do
      record_value = Value.record([])

      assert_raise RuntimeError, fn ->
        Value.negate!(record_value)
      end
    end
  end
end
