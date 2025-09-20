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

  describe "Test operators applied to values" do
    ############## Plus ##############
    test "integer plus integer" do
      assert Value.add!(Value.integer(1), Value.integer(4)) == Value.integer(5)
    end

    test "float plus float" do
      assert Value.add!(Value.float(1.5), Value.float(4.1)) == Value.float(5.6)
    end

    ############## Minus ##############
    test "integer minus integer" do
      assert Value.subtract!(Value.integer(10), Value.integer(3)) == Value.integer(7)
    end

    test "float minus float" do
      assert Value.subtract!(Value.float(5.5), Value.float(2.2)) == Value.float(3.3)
    end

    ############## Multiply ##############
    test "integer multiply integer" do
      assert Value.multiply!(Value.integer(3), Value.integer(4)) == Value.integer(12)
    end

    test "float multiply float" do
      assert Value.multiply!(Value.float(2.5), Value.float(3.0)) == Value.float(7.5)
    end

    ############## Divide ##############
    test "integer divide integer returns integer" do
      assert Value.divide!(Value.integer(6), Value.integer(2)) == Value.integer(3)
    end

    test "integer divide integer floors positive result" do
      assert Value.divide!(Value.integer(7), Value.integer(2)) == Value.integer(3)
    end

    test "integer divide integer floors toward negative infinity" do
      assert Value.divide!(Value.integer(-7), Value.integer(2)) == Value.integer(-4)
    end

    test "integer divide integer floors negative dividend" do
      assert Value.divide!(Value.integer(7), Value.integer(-2)) == Value.integer(-4)
    end

    test "integer divide integer floors both negative" do
      assert Value.divide!(Value.integer(-7), Value.integer(-2)) == Value.integer(3)
    end

    test "integer divide by zero raises error" do
      assert_raise RuntimeError, "Division by zero", fn ->
        Value.divide!(Value.integer(5), Value.integer(0))
      end
    end

    test "float divide by zero raises error" do
      assert_raise RuntimeError, "Division by zero", fn ->
        Value.divide!(Value.float(5.0), Value.float(0.0))
      end
    end

    test "float divide float" do
      assert Value.divide!(Value.float(9.0), Value.float(3.0)) == Value.float(3.0)
    end

    ############## Append ##############
    test "text append text" do
      assert Value.append!(Value.text("Hello "), Value.text("World")) == Value.text("Hello World")
    end
  end
end
