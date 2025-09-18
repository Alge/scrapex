defmodule Scrapex.Parser.GroupedExpressionTest do
  use ExUnit.Case, async: true

  alias Scrapex.{Parser, Token}
  alias Scrapex.AST

  describe "grouped expressions" do
    test "parses an empty grouped expression () as a hole" do
      # Input: "()"
      # This is the simplest possible case that exposes the bug.
      input = [
        Token.new(:left_paren, 1, 1),
        Token.new(:right_paren, 1, 2),
        Token.new(:eof, 1, 3)
      ]

      # The expected AST for `()` is a simple hole.
      expected = AST.hole()

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a grouped expression with a simple literal" do
      # Input: "(1)"
      input = [
        Token.new(:left_paren, 1, 1),
        Token.new(:integer, 1, 1, 2),
        Token.new(:right_paren, 1, 3),
        Token.new(:eof, 1, 4)
      ]

      # Note: Grouping parentheses are usually for precedence and often don't
      # need a dedicated AST node. The parser can just return the inner expression.
      # If you wanted to preserve the grouping, you would expect AST.group_expression(AST.integer(1)).
      expected = AST.integer(1)

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a grouped expression with a binary operation" do
      # Input: "(1 + 2)"
      input = [
        Token.new(:left_paren, 1, 1),
        Token.new(:integer, 1, 1, 2),
        Token.new(:plus, 1, 4),
        Token.new(:integer, 2, 1, 6),
        Token.new(:right_paren, 1, 7),
        Token.new(:eof, 1, 8)
      ]

      expected = AST.binary_op(AST.integer(1), :plus, AST.integer(2))

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end
end
