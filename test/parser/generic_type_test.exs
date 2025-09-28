# test/parser/generic_type_test.exs

defmodule Scrapex.Parser.GenericTypeTest do
  use ExUnit.Case, async: true

  alias Scrapex.{Parser, Token, AST}

  describe "generic type declarations" do
    @tag :skip
    test "parses a type declaration with a single generic parameter" do
      # Input: "maybe : a => #some a #none"
      input = [
        Token.new(:identifier, "maybe", 1, 1),
        Token.new(:colon, 1, 7),
        Token.new(:identifier, "a", 1, 9),
        Token.new(:double_arrow, 1, 11),
        Token.new(:hashtag, 1, 14),
        Token.new(:identifier, "some", 1, 15),
        Token.new(:identifier, "a", 1, 20),
        Token.new(:hashtag, 1, 22),
        Token.new(:identifier, "none", 1, 23),
        Token.new(:eof, 1, 27)
      ]

      # This will fail first with UndefinedFunctionError.
      expected =
        AST.generic_type_declaration(
          # The name of the type
          "maybe",
          # The list of generic parameters
          [AST.identifier("a")],
          # The body is a type_union of the variants
          AST.type_union([
            AST.variant("some", AST.identifier("a")),
            AST.variant("none")
          ])
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    @tag :skip
    test "parses a type declaration with multiple generic parameters" do
      # Input: "point : x => y => #2d {x:x, y:y}"
      input = [
        Token.new(:identifier, "point", 1, 1),
        Token.new(:colon, 1, 7),
        Token.new(:identifier, "x", 1, 9),
        Token.new(:double_arrow, 1, 11),
        Token.new(:identifier, "y", 1, 14),
        Token.new(:double_arrow, 1, 16),
        Token.new(:hashtag, 1, 19),
        Token.new(:identifier, "2d", 1, 20),
        Token.new(:left_brace, 1, 23),
        Token.new(:identifier, "x", 1, 24),
        Token.new(:colon, 1, 25),
        Token.new(:identifier, "x", 1, 26),
        Token.new(:comma, 1, 27),
        Token.new(:identifier, "y", 1, 29),
        Token.new(:colon, 1, 30),
        Token.new(:identifier, "y", 1, 31),
        Token.new(:right_brace, 1, 32),
        Token.new(:eof, 1, 33)
      ]

      expected =
        AST.generic_type_declaration(
          "point",
          [AST.identifier("x"), AST.identifier("y")],
          AST.type_union([
            AST.variant(
              "2d",
              AST.record_type([
                {AST.identifier("x"), AST.identifier("x")},
                {AST.identifier("y"), AST.identifier("y")}
              ])
            )
          ])
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end
end
