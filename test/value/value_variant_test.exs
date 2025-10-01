defmodule Scrapex.Value.VariantTest do
  use ExUnit.Case

  alias Scrapex.Value

  describe "variant values" do
    test "create variant value without payload" do
      assert Value.variant("true") == {:variant, "true", {:hole}}
    end

    test "create variant value with a payload" do
      payload = Value.integer(42)
      assert Value.variant("some", payload) == {:variant, "some", payload}
    end

    test "display variant without payload" do
      variant_value = Value.variant("success")
      assert Value.display(variant_value) == {:ok, "#success"}
    end

    test "display! variant without payload" do
      variant_value = Value.variant("error")
      assert Value.display!(variant_value) == "#error"
    end

    test "display variant with a simple payload" do
      payload = Value.integer(10)
      variant_value = Value.variant("count", payload)
      assert Value.display(variant_value) == {:ok, "#count 10"}
    end

    test "display! variant with a complex payload" do
      payload = Value.record([{"id", Value.integer(123)}])
      variant_value = Value.variant("user", payload)
      assert Value.display!(variant_value) == "#user {id: 123}"
    end

    test "negate returns error for variant" do
      variant_value = Value.variant("true")
      result = Value.negate(variant_value)
      assert {:error, _reason} = result
    end

    test "negate! raises error for variant" do
      variant_value = Value.variant("false")

      assert_raise RuntimeError, fn ->
        Value.negate!(variant_value)
      end
    end
  end
end
