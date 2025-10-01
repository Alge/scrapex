defmodule Scrapex.Parser.GenericParameterTest do
  use ExUnit.Case
  alias Scrapex.{Parser, Token, AST}

  describe "type-level parameters" do
    test "parses single type parameter" do
      # Input: "id : x => #some x"
      input = [
        Token.new(:identifier, "id", 1, 1),
        Token.new(:colon, 1, 4),
        Token.new(:identifier, "x", 1, 6),
        Token.new(:double_arrow, 1, 8),
        Token.new(:hashtag, 1, 11),
        Token.new(:identifier, "some", 1, 12),
        Token.new(:identifier, "x", 1, 17),
        Token.new(:eof, 1, 18)
      ]

      {:ok, result} = Parser.parse(input)

      expected =
        AST.generic_type_declaration(
          "id",
          [AST.identifier("x")],
          AST.type_union([AST.variant_def("some", AST.identifier("x"))])
        )

      assert result == expected
    end

    test "parses multiple type parameters with pipe-separated variants" do
      # Input: "point : x => y => z => #2d {x = x, y = y} | #3d {x = x, y = y, z = z}"
      input = [
        Token.new(:identifier, "point", 1, 1),
        Token.new(:colon, 1, 7),
        Token.new(:identifier, "x", 1, 9),
        Token.new(:double_arrow, 1, 11),
        Token.new(:identifier, "y", 1, 14),
        Token.new(:double_arrow, 1, 16),
        Token.new(:identifier, "z", 1, 19),
        Token.new(:double_arrow, 1, 21),
        Token.new(:hashtag, 1, 24),
        Token.new(:identifier, "2d", 1, 25),
        Token.new(:left_brace, 1, 28),
        Token.new(:identifier, "x", 1, 29),
        Token.new(:equals, 1, 31),
        Token.new(:identifier, "x", 1, 33),
        Token.new(:comma, 1, 34),
        Token.new(:identifier, "y", 1, 36),
        Token.new(:equals, 1, 38),
        Token.new(:identifier, "y", 1, 40),
        Token.new(:right_brace, 1, 41),
        Token.new(:pipe, 1, 43),
        Token.new(:hashtag, 1, 45),
        Token.new(:identifier, "3d", 1, 46),
        Token.new(:left_brace, 1, 49),
        Token.new(:identifier, "x", 1, 50),
        Token.new(:equals, 1, 52),
        Token.new(:identifier, "x", 1, 54),
        Token.new(:comma, 1, 55),
        Token.new(:identifier, "y", 1, 57),
        Token.new(:equals, 1, 59),
        Token.new(:identifier, "y", 1, 61),
        Token.new(:comma, 1, 62),
        Token.new(:identifier, "z", 1, 64),
        Token.new(:equals, 1, 66),
        Token.new(:identifier, "z", 1, 68),
        Token.new(:right_brace, 1, 69),
        Token.new(:eof, 1, 70)
      ]

      {:ok, result} = Parser.parse(input)

      expected =
        AST.generic_type_declaration(
          "point",
          [AST.identifier("x"), AST.identifier("y"), AST.identifier("z")],
          AST.type_union([
            AST.variant_def(
              "2d",
              AST.record_literal([
                AST.record_expression_field("x", AST.identifier("x")),
                AST.record_expression_field("y", AST.identifier("y"))
              ])
            ),
            AST.variant_def(
              "3d",
              AST.record_literal([
                AST.record_expression_field("x", AST.identifier("x")),
                AST.record_expression_field("y", AST.identifier("y")),
                AST.record_expression_field("z", AST.identifier("z"))
              ])
            )
          ])
        )

      assert result == expected
    end

    test "parses result type from guide" do
      # Input: "result : value => #ok value | #err text"
      input = [
        Token.new(:identifier, "result", 1, 1),
        Token.new(:colon, 1, 8),
        Token.new(:identifier, "value", 1, 10),
        Token.new(:double_arrow, 1, 16),
        Token.new(:hashtag, 1, 19),
        Token.new(:identifier, "ok", 1, 20),
        Token.new(:identifier, "value", 1, 23),
        Token.new(:pipe, 1, 29),
        Token.new(:hashtag, 1, 31),
        Token.new(:identifier, "err", 1, 32),
        Token.new(:identifier, "text", 1, 36),
        Token.new(:eof, 1, 40)
      ]

      {:ok, result} = Parser.parse(input)

      expected =
        AST.generic_type_declaration(
          "result",
          [AST.identifier("value")],
          AST.type_union([
            AST.variant_def("ok", AST.identifier("value")),
            AST.variant_def("err", AST.identifier("text"))
          ])
        )

      assert result == expected
    end
  end
end
