defmodule Scrapex.Value.ListTest do
  use ExUnit.Case

  alias Scrapex.Value

  describe "list operations" do
    ############## Cons (>+) ##############

    test "cons integer to integer list" do
      list_value = Value.list([Value.integer(2), Value.integer(3)])
      result = Value.cons!(Value.integer(1), list_value)
      expected = Value.list([Value.integer(1), Value.integer(2), Value.integer(3)])
      assert result == expected
    end

    test "cons text to text list" do
      list_value = Value.list([Value.text("world")])
      result = Value.cons!(Value.text("hello"), list_value)
      expected = Value.list([Value.text("hello"), Value.text("world")])
      assert result == expected
    end

    test "cons to empty list" do
      empty_list = Value.list([])
      result = Value.cons!(Value.integer(42), empty_list)
      expected = Value.list([Value.integer(42)])
      assert result == expected
    end

    test "cons returns error for non-list second argument" do
      result = Value.cons(Value.integer(1), Value.integer(2))
      assert {:error, _reason} = result
    end

    test "cons! raises error for non-list second argument" do
      assert_raise RuntimeError, fn ->
        Value.cons!(Value.integer(1), Value.integer(2))
      end
    end

    # TODO: Type system not present yet
    @tag :skip
    test "cons returns error for type mismatch in list elements" do
      text_list = Value.list([Value.text("hello")])
      result = Value.cons(Value.integer(1), text_list)
      assert {:error, _reason} = result
    end

    test "nested cons operations" do
      # 1 >+ (2 >+ [3]) should produce [1, 2, 3]
      inner_list = Value.list([Value.integer(3)])
      middle_result = Value.cons!(Value.integer(2), inner_list)
      final_result = Value.cons!(Value.integer(1), middle_result)
      expected = Value.list([Value.integer(1), Value.integer(2), Value.integer(3)])
      assert final_result == expected
    end

    ############## Append to List (+<) ##############

    test "append to list integer to integer list" do
      list_value = Value.list([Value.integer(1), Value.integer(2)])
      result = Value.append_to_list!(list_value, Value.integer(3))
      expected = Value.list([Value.integer(1), Value.integer(2), Value.integer(3)])
      assert result == expected
    end

    test "append to list text to text list" do
      list_value = Value.list([Value.text("hello"), Value.text("world")])
      result = Value.append_to_list!(list_value, Value.text("!"))
      expected = Value.list([Value.text("hello"), Value.text("world"), Value.text("!")])
      assert result == expected
    end

    test "append to list to empty list" do
      empty_list = Value.list([])
      result = Value.append_to_list!(empty_list, Value.integer(42))
      expected = Value.list([Value.integer(42)])
      assert result == expected
    end

    test "append to list creates nested list when appending list" do
      list_value = Value.list([Value.integer(1), Value.integer(2)])
      nested_list = Value.list([Value.integer(3), Value.integer(4)])
      result = Value.append_to_list!(list_value, nested_list)

      expected =
        Value.list([
          Value.integer(1),
          Value.integer(2),
          Value.list([Value.integer(3), Value.integer(4)])
        ])

      assert result == expected
    end

    test "append to list with variants" do
      list_value = Value.list([Value.variant("ok"), Value.variant("error")])
      result = Value.append_to_list!(list_value, Value.variant("loading"))

      expected =
        Value.list([Value.variant("ok"), Value.variant("error"), Value.variant("loading")])

      assert result == expected
    end

    test "append to list returns error for non-list first argument" do
      not_list = Value.integer(42)
      result = Value.append_to_list(not_list, Value.integer(3))
      assert {:error, _reason} = result
    end

    test "append to list! raises error for non-list first argument" do
      not_list = Value.text("hello")

      assert_raise RuntimeError, fn ->
        Value.append_to_list!(not_list, Value.text("world"))
      end
    end

    test "nested append to list operations" do
      # [1] +< 2 +< 3 equivalent
      list1 = Value.list([Value.integer(1)])
      list2 = Value.append_to_list!(list1, Value.integer(2))
      final_result = Value.append_to_list!(list2, Value.integer(3))
      expected = Value.list([Value.integer(1), Value.integer(2), Value.integer(3)])
      assert final_result == expected
    end
  end
end
