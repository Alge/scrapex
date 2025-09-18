defmodule Scrapex.Parser.VariantConstructionTest do
  use ExUnit.Case, async: true

  alias Scrapex.{Parser, Token, AST}

  describe "variant construction expressions" do
    test "parses a simple variant construction" do
      # Input: "scoop::chocolate"
      input = [
        Token.new(:identifier, "scoop", 1, 1),
        Token.new(:double_colon, 1, 6),
        Token.new(:identifier, "chocolate", 1, 8),
        Token.new(:eof, 1, 17)
      ]

      # We'll need a new, specific AST node.
      expected = AST.variant_constructor(AST.identifier("scoop"), AST.identifier("chocolate"))

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a variant construction with a payload" do
      # Input: "c::radius 4"
      input = [
        Token.new(:identifier, "c", 1, 1),
        Token.new(:double_colon, 1, 2),
        Token.new(:identifier, "radius", 1, 4),
        Token.new(:integer, 4, 1, 11),
        Token.new(:eof, 1, 12)
      ]

      expected =
        AST.variant_constructor(
          AST.identifier("c"),
          AST.function_app(AST.identifier("radius"), AST.integer(4))
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end
end
