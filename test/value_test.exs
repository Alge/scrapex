defmodule Scrapex.ValueTest do
  use ExUnit.Case

  alias Scrapex.Value

  describe "Evaluate values" do
    test "Create integer value" do
      assert Value.integer(123) == {:integer, 123}
    end

    test "Create float value" do
      assert Value.float(12.3) == {:float, 12.3}
    end

    test "Create text value" do
      assert Value.text("Hello!") == {:text, "Hello!"}
    end
  end

  describe "Display string representation for values" do
    test "display integer" do
      assert Value.display!(Value.integer(123)) == "123"
    end

    test "display float" do
      assert Value.display!(Value.float(1.23)) == "1.23"
    end

    test "display text" do
      assert Value.display!(Value.text("Hello")) == "Hello"
    end

    test "display crashes on unimplemented type" do
      # Test that it raises any exception
      assert_raise RuntimeError, fn ->
        Value.display!({:not_implemented, 123})
      end
    end
  end
end
