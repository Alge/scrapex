defmodule Scrapex.ParserTest do
  use ExUnit.Case
  alias Scrapex.{Parser, AST, Token}

  test "parses a simple binary expression with plus" do
    # Input represents "1 + 2"
    input = [
      Token.new(:integer, 1, 1, 1),
      Token.new(:plus, 1, 3),
      Token.new(:integer, 2, 1, 5),
      Token.new(:eof, 1, 6)
    ]

    expected =
      AST.binary_op(
        AST.integer(1),
        :plus,
        AST.integer(2)
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses an expression with parentheses to override precedence" do
    # Input represents "(1 + 2) * 3"
    input = [
      Token.new(:left_paren, 1, 1),
      Token.new(:integer, 1, 1, 2),
      Token.new(:plus, 1, 4),
      Token.new(:integer, 2, 1, 6),
      Token.new(:right_paren, 1, 7),
      Token.new(:multiply, 1, 9),
      Token.new(:integer, 3, 1, 11),
      Token.new(:eof, 1, 12)
    ]

    expected =
      AST.binary_op(
        AST.binary_op(AST.integer(1), :plus, AST.integer(2)),
        :multiply,
        AST.integer(3)
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  # --- Tests for error conditions ---

  test "returns an error for an expression ending in a binary operator" do
    input = [
      Token.new(:integer, 123, 1, 1),
      Token.new(:semicolon, 1, 4),
      Token.new(:eof, 1, 5)
    ]

    assert {:error, _reason} = Parser.parse(input)
  end

  test "parses a simple unary negation expression" do
    # Input represents the code "-123"
    input = [
      Token.new(:minus, 1, 1),
      Token.new(:integer, 123, 1, 2),
      Token.new(:eof, 1, 5)
    ]

    # The expected AST is a unary operation node wrapping the integer.
    expected =
      AST.unary_op(
        :minus,
        AST.integer(123)
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses consecutive function bindings as siblings in a where-clause" do
    # This test is designed to catch the precedence bug between `->` and `;`.
    # The code represents:
    # main_body
    # ; f = x -> x
    # ; g = y -> y

    # The parser should group this as: `main_body ; (f = ... ; g = ...)`
    # The incorrect, buggy behavior is to group it as: `main_body ; f = (x -> (x ; g = ...))`

    input = [
      Token.new(:identifier, "main_body", 1, 1),
      Token.new(:semicolon, 1, 11),
      Token.new(:identifier, "f", 1, 13),
      Token.new(:equals, 1, 15),
      Token.new(:identifier, "x", 1, 17),
      Token.new(:right_arrow, 1, 19),
      Token.new(:identifier, "x", 1, 22),
      Token.new(:semicolon, 1, 23),
      Token.new(:identifier, "g", 1, 25),
      Token.new(:equals, 1, 27),
      Token.new(:identifier, "y", 1, 29),
      Token.new(:right_arrow, 1, 31),
      Token.new(:identifier, "y", 1, 34),
      Token.new(:eof, 1, 35)
    ]

    # The expected AST for the `f = x -> x` lambda
    f_lambda =
      AST.pattern_match_expression([
        AST.pattern_clause(AST.identifier("x"), AST.identifier("x"))
      ])

    # The expected AST for the `g = y -> y` lambda
    g_lambda =
      AST.pattern_match_expression([
        AST.pattern_clause(AST.identifier("y"), AST.identifier("y"))
      ])

    # The correct AST structure: a nested `where` with two sibling bindings.
    expected =
      AST.where(
        AST.identifier("main_body"),
        AST.where(
          AST.binding("f", f_lambda),
          AST.binding("g", g_lambda)
        )
      )

    assert {:ok, ^expected} = Parser.parse(input)
  end

  describe "comparison operators" do
    test "parses equality with correct precedence" do
      # Input: "1 + 2 == 3 * 4" should parse as (1 + 2) == (3 * 4)
      input = [
        Token.new(:integer, 1, 1, 1),
        Token.new(:plus, 1, 3),
        Token.new(:integer, 2, 1, 5),
        Token.new(:double_equals, 1, 7),
        Token.new(:integer, 3, 1, 10),
        Token.new(:multiply, 1, 12),
        Token.new(:integer, 4, 1, 14),
        Token.new(:eof, 1, 15)
      ]

      expected =
        AST.binary_op(
          AST.binary_op(AST.integer(1), :plus, AST.integer(2)),
          :double_equals,
          AST.binary_op(AST.integer(3), :multiply, AST.integer(4))
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses all comparison operators" do
      # Input: "a < b > c == d != e"
      input = [
        Token.new(:identifier, "a", 1, 1),
        Token.new(:less_than, 1, 3),
        Token.new(:identifier, "b", 1, 5),
        Token.new(:greater_than, 1, 7),
        Token.new(:identifier, "c", 1, 9),
        Token.new(:double_equals, 1, 11),
        Token.new(:identifier, "d", 1, 14),
        Token.new(:not_equals, 1, 16),
        Token.new(:identifier, "e", 1, 19),
        Token.new(:eof, 1, 20)
      ]

      expected =
        AST.binary_op(
          AST.binary_op(
            AST.binary_op(
              AST.binary_op(AST.identifier("a"), :less_than, AST.identifier("b")),
              :greater_than,
              AST.identifier("c")
            ),
            :double_equals,
            AST.identifier("d")
          ),
          :not_equals,
          AST.identifier("e")
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end
end
