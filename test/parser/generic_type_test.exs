defmodule Scrapex.Parser.GenericTypeTest do
  use ExUnit.Case, async: true

  alias Scrapex.{Parser, Token, AST}

  describe "generic type declarations" do
    test "parses a generic result type" do
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

      expected =
        AST.generic_type_declaration(
          "result",
          [AST.identifier("value")],
          AST.type_union([
            AST.variant_def("ok", AST.identifier("value")),
            AST.variant_def("err", AST.identifier("text"))
          ])
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses point type from guide" do
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
        Token.new(:identifier, "x", 1, 30),
        Token.new(:equals, 1, 32),
        Token.new(:identifier, "x", 1, 34),
        Token.new(:comma, 1, 35),
        Token.new(:identifier, "y", 1, 37),
        Token.new(:equals, 1, 39),
        Token.new(:identifier, "y", 1, 41),
        Token.new(:right_brace, 1, 43),
        Token.new(:pipe, 1, 45),
        Token.new(:hashtag, 1, 47),
        Token.new(:identifier, "3d", 1, 48),
        Token.new(:left_brace, 1, 51),
        Token.new(:identifier, "x", 1, 53),
        Token.new(:equals, 1, 55),
        Token.new(:identifier, "x", 1, 57),
        Token.new(:comma, 1, 58),
        Token.new(:identifier, "y", 1, 60),
        Token.new(:equals, 1, 62),
        Token.new(:identifier, "y", 1, 64),
        Token.new(:comma, 1, 65),
        Token.new(:identifier, "z", 1, 67),
        Token.new(:equals, 1, 69),
        Token.new(:identifier, "z", 1, 71),
        Token.new(:right_brace, 1, 73),
        Token.new(:eof, 1, 74)
      ]

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

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end
end
