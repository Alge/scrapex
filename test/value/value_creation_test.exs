defmodule Scrapex.Value.CreationTest do
  use ExUnit.Case

  alias Scrapex.Value

  describe "value creation" do
    test "create integer value" do
      assert Value.integer(123) == {:integer, 123}
    end

    test "create float value" do
      assert Value.float(12.3) == {:float, 12.3}
    end

    test "create text value" do
      assert Value.text("Hello!") == {:text, "Hello!"}
    end
  end

  describe "value display" do
    test "display integer" do
      assert Value.display!(Value.integer(123)) == "123"
    end

    test "display float" do
      assert Value.display!(Value.float(1.23)) == "1.23"
    end

    test "display text" do
      assert Value.display!(Value.text("Hello")) == "\"Hello\""
    end

    test "display! empty list" do
      assert Value.display!(Value.list([])) == "[]"
    end

    test "display! list with multiple integers" do
      list_value =
        Value.list([
          Value.integer(1),
          Value.integer(2),
          Value.integer(3)
        ])

      assert Value.display!(list_value) == "[1, 2, 3]"
    end

    test "display list with floats" do
      list_value =
        Value.list([
          Value.float(1.5),
          Value.float(2.7)
        ])

      assert Value.display(list_value) == {:ok, "[1.5, 2.7]"}
    end

    test "display! list with text values" do
      list_value =
        Value.list([
          Value.text("hello"),
          Value.text("world")
        ])

      assert Value.display!(list_value) == "[\"hello\", \"world\"]"
    end

    test "display! nested lists" do
      inner_list1 = Value.list([Value.integer(1), Value.integer(2)])
      inner_list2 = Value.list([Value.integer(3), Value.integer(4)])
      outer_list = Value.list([inner_list1, inner_list2])

      assert Value.display!(outer_list) == "[[1, 2], [3, 4]]"
    end

    test "display crashes on unimplemented type" do
      assert_raise RuntimeError, fn ->
        Value.display!({:not_implemented, 123})
      end
    end
  end
end
