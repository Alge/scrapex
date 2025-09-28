defmodule Scrapex.Value.ComparisonTest do
  use ExUnit.Case

  alias Scrapex.Value

  describe "comparison operations" do
    ############## Equal (==) ##############
    test "integer equal integer true" do
      result = Value.equal(Value.integer(5), Value.integer(5))
      assert result == {:ok, Value.variant("true")}
    end

    test "integer equal integer false" do
      result = Value.equal(Value.integer(3), Value.integer(7))
      assert result == {:ok, Value.variant("false")}
    end

    test "float equal float true" do
      result = Value.equal(Value.float(3.14), Value.float(3.14))
      assert result == {:ok, Value.variant("true")}
    end

    test "float equal float false" do
      result = Value.equal(Value.float(1.0), Value.float(2.0))
      assert result == {:ok, Value.variant("false")}
    end

    test "text equal text true" do
      result = Value.equal(Value.text("hello"), Value.text("hello"))
      assert result == {:ok, Value.variant("true")}
    end

    test "text equal text false" do
      result = Value.equal(Value.text("hello"), Value.text("world"))
      assert result == {:ok, Value.variant("false")}
    end

    test "variant equal variant true" do
      result = Value.equal(Value.variant("ok"), Value.variant("ok"))
      assert result == {:ok, Value.variant("true")}
    end

    test "variant equal variant false" do
      result = Value.equal(Value.variant("ok"), Value.variant("error"))
      assert result == {:ok, Value.variant("false")}
    end

    test "equal returns error for different types" do
      result = Value.equal(Value.integer(5), Value.text("5"))
      assert {:error, _reason} = result
    end

    ############## Not Equal (!=) ##############
    test "integer not equal integer true" do
      result = Value.not_equal(Value.integer(3), Value.integer(7))
      assert result == {:ok, Value.variant("true")}
    end

    test "integer not equal integer false" do
      result = Value.not_equal(Value.integer(5), Value.integer(5))
      assert result == {:ok, Value.variant("false")}
    end

    test "text not equal text true" do
      result = Value.not_equal(Value.text("hello"), Value.text("world"))
      assert result == {:ok, Value.variant("true")}
    end

    test "text not equal text false" do
      result = Value.not_equal(Value.text("same"), Value.text("same"))
      assert result == {:ok, Value.variant("false")}
    end

    test "variant not equal variant true" do
      result = Value.not_equal(Value.variant("ok"), Value.variant("error"))
      assert result == {:ok, Value.variant("true")}
    end

    test "variant not equal variant false" do
      result = Value.not_equal(Value.variant("loading"), Value.variant("loading"))
      assert result == {:ok, Value.variant("false")}
    end

    test "not equal returns error for different types" do
      result = Value.not_equal(Value.integer(5), Value.text("hello"))
      assert {:error, _reason} = result
    end

    ############## Less Than (<) ##############
    test "integer less than integer true" do
      result = Value.less_than(Value.integer(3), Value.integer(7))
      assert result == {:ok, Value.variant("true")}
    end

    test "integer less than integer false" do
      result = Value.less_than(Value.integer(7), Value.integer(3))
      assert result == {:ok, Value.variant("false")}
    end

    test "integer less than integer equal false" do
      result = Value.less_than(Value.integer(5), Value.integer(5))
      assert result == {:ok, Value.variant("false")}
    end

    test "float less than float true" do
      result = Value.less_than(Value.float(1.5), Value.float(2.7))
      assert result == {:ok, Value.variant("true")}
    end

    test "float less than float false" do
      result = Value.less_than(Value.float(3.14), Value.float(1.0))
      assert result == {:ok, Value.variant("false")}
    end

    test "float less than float equal false" do
      result = Value.less_than(Value.float(2.5), Value.float(2.5))
      assert result == {:ok, Value.variant("false")}
    end

    test "text less than text true" do
      result = Value.less_than(Value.text("apple"), Value.text("banana"))
      assert result == {:ok, Value.variant("true")}
    end

    test "text less than text false" do
      result = Value.less_than(Value.text("zebra"), Value.text("apple"))
      assert result == {:ok, Value.variant("false")}
    end

    test "text less than text equal false" do
      result = Value.less_than(Value.text("same"), Value.text("same"))
      assert result == {:ok, Value.variant("false")}
    end

    test "less than returns error for different types" do
      result = Value.less_than(Value.integer(5), Value.text("hello"))
      assert {:error, _reason} = result
    end

    test "less than returns error for variants" do
      result = Value.less_than(Value.variant("ok"), Value.variant("error"))
      assert {:error, _reason} = result
    end

    ############## Greater Than (>) ##############
    test "integer greater than integer true" do
      result = Value.greater_than(Value.integer(7), Value.integer(3))
      assert result == {:ok, Value.variant("true")}
    end

    test "integer greater than integer false" do
      result = Value.greater_than(Value.integer(3), Value.integer(7))
      assert result == {:ok, Value.variant("false")}
    end

    test "integer greater than integer equal false" do
      result = Value.greater_than(Value.integer(5), Value.integer(5))
      assert result == {:ok, Value.variant("false")}
    end

    test "float greater than float true" do
      result = Value.greater_than(Value.float(3.14), Value.float(1.0))
      assert result == {:ok, Value.variant("true")}
    end

    test "float greater than float false" do
      result = Value.greater_than(Value.float(1.5), Value.float(2.7))
      assert result == {:ok, Value.variant("false")}
    end

    test "text greater than text true" do
      result = Value.greater_than(Value.text("zebra"), Value.text("apple"))
      assert result == {:ok, Value.variant("true")}
    end

    test "text greater than text false" do
      result = Value.greater_than(Value.text("apple"), Value.text("banana"))
      assert result == {:ok, Value.variant("false")}
    end

    test "greater than returns error for different types" do
      result = Value.greater_than(Value.float(2.5), Value.integer(2))
      assert {:error, _reason} = result
    end

    test "greater than returns error for variants" do
      result = Value.greater_than(Value.variant("ok"), Value.variant("loading"))
      assert {:error, _reason} = result
    end

    ############## Edge Cases ##############
    test "comparison with zero values" do
      assert Value.equal(Value.integer(0), Value.integer(0)) == {:ok, Value.variant("true")}
      assert Value.equal(Value.float(0.0), Value.float(0.0)) == {:ok, Value.variant("true")}
      assert Value.less_than(Value.integer(-1), Value.integer(0)) == {:ok, Value.variant("true")}

      assert Value.greater_than(Value.integer(1), Value.integer(0)) ==
               {:ok, Value.variant("true")}
    end

    test "comparison with negative numbers" do
      assert Value.less_than(Value.integer(-5), Value.integer(-3)) == {:ok, Value.variant("true")}

      assert Value.greater_than(Value.integer(-3), Value.integer(-5)) ==
               {:ok, Value.variant("true")}

      assert Value.equal(Value.integer(-42), Value.integer(-42)) == {:ok, Value.variant("true")}
      assert Value.not_equal(Value.integer(-1), Value.integer(-2)) == {:ok, Value.variant("true")}
    end

    test "comparison with empty text" do
      assert Value.equal(Value.text(""), Value.text("")) == {:ok, Value.variant("true")}
      assert Value.not_equal(Value.text(""), Value.text("a")) == {:ok, Value.variant("true")}
      assert Value.less_than(Value.text(""), Value.text("a")) == {:ok, Value.variant("true")}
      assert Value.greater_than(Value.text("a"), Value.text("")) == {:ok, Value.variant("true")}
    end

    test "comparison consistency" do
      # If a == b, then !(a != b) and !(a < b) and !(a > b)
      val1 = Value.integer(42)
      val2 = Value.integer(42)

      assert Value.equal(val1, val2) == {:ok, Value.variant("true")}
      assert Value.not_equal(val1, val2) == {:ok, Value.variant("false")}
      assert Value.less_than(val1, val2) == {:ok, Value.variant("false")}
      assert Value.greater_than(val1, val2) == {:ok, Value.variant("false")}
    end
  end
end
