defmodule Scrapex.Value.ArithmeticTest do
  use ExUnit.Case

  alias Scrapex.Value

  describe "arithmetic operations" do
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

    ############## Negate ##############
    test "integer negate positive" do
      assert Value.negate(Value.integer(42)) == {:ok, Value.integer(-42)}
    end

    test "integer negate negative" do
      assert Value.negate(Value.integer(-42)) == {:ok, Value.integer(42)}
    end

    test "integer negate zero" do
      assert Value.negate(Value.integer(0)) == {:ok, Value.integer(0)}
    end

    test "float negate positive" do
      assert Value.negate(Value.float(3.14)) == {:ok, Value.float(-3.14)}
    end

    test "float negate negative" do
      assert Value.negate(Value.float(-2.71)) == {:ok, Value.float(2.71)}
    end

    test "float negate zero" do
      assert Value.negate(Value.float(0.0)) == {:ok, Value.float(-0.0)}
    end

    test "negate! integer positive" do
      assert Value.negate!(Value.integer(42)) == Value.integer(-42)
    end

    test "negate! integer negative" do
      assert Value.negate!(Value.integer(-42)) == Value.integer(42)
    end

    test "negate! float positive" do
      assert Value.negate!(Value.float(3.14)) == Value.float(-3.14)
    end

    test "negate! float negative" do
      assert Value.negate!(Value.float(-2.71)) == Value.float(2.71)
    end

    test "negate returns error for text" do
      result = Value.negate(Value.text("hello"))
      assert {:error, _reason} = result
    end

    test "negate! raises error for text" do
      assert_raise RuntimeError, fn ->
        Value.negate!(Value.text("hello"))
      end
    end

    test "negate returns error for list" do
      result = Value.negate(Value.list([Value.integer(1)]))
      assert {:error, _reason} = result
    end

    test "negate! raises error for list" do
      assert_raise RuntimeError, fn ->
        Value.negate!(Value.list([Value.integer(1)]))
      end
    end
  end
end
