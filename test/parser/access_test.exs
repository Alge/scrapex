# test/parser/access_test.exs

defmodule Scrapex.Parser.AccessTest do
  use ExUnit.Case, async: true

  alias Scrapex.{Parser, Token, AST}

  describe "field access expressions" do
    @tag :skip
    test "parses a simple record field access" do
      # Input: "my_record.field"
      input = [
        Token.new(:identifier, "my_record", 1, 1),
        Token.new(:dot, 1, 10),
        Token.new(:identifier, "field", 1, 11),
        Token.new(:eof, 1, 16)
      ]

      expected = AST.field_access(AST.identifier("my_record"), "field")

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses chained record field access" do
      # Input: "a.b.c"
      input = [
        Token.new(:identifier, "a", 1, 1),
        Token.new(:dot, 1, 2),
        Token.new(:identifier, "b", 1, 3),
        Token.new(:dot, 1, 4),
        Token.new(:identifier, "c", 1, 5),
        Token.new(:eof, 1, 6)
      ]

      # The AST for chained access should be nested, reflecting the left-to-right precedence.
      # It should be parsed as (a.b).c
      expected =
        AST.field_access(
          AST.field_access(AST.identifier("a"), "b"),
          "c"
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end
end
