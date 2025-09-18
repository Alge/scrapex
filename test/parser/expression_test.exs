# test/parser/expression_test.exs
require Logger

defmodule Scrapex.Parser.ExpressionTest do
  use ExUnit.Case, async: true

  alias Scrapex.{Parser, Token}
  alias Scrapex.AST

  describe "list literal expressions" do
    test "parses an empty list literal" do
      # Input: []
      input = [
        Token.new(:left_bracket, 1, 1),
        Token.new(:right_bracket, 1, 2),
        Token.new(:eof, 1, 3)
      ]

      expected = AST.list_literal([])
      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a list of integer literals" do
      # Input: [1, 2, 3]
      input = [
        Token.new(:left_bracket, 1, 1),
        Token.new(:integer, 1, 1, 2),
        Token.new(:comma, 1, 3),
        Token.new(:integer, 2, 1, 4),
        Token.new(:comma, 1, 5),
        Token.new(:integer, 3, 1, 6),
        Token.new(:right_bracket, 1, 7),
        Token.new(:eof, 1, 8)
      ]

      expected =
        AST.list_literal([
          AST.integer(1),
          AST.integer(2),
          AST.integer(3)
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a list of complex expressions" do
      # Input: [1 + 2, f()]
      input = [
        Token.new(:left_bracket, 1, 1),
        Token.new(:integer, 1, 1, 2),
        Token.new(:plus, 1, 4),
        Token.new(:integer, 2, 1, 6),
        Token.new(:comma, 1, 7),
        Token.new(:identifier, "f", 1, 9),
        Token.new(:left_paren, 1, 10),
        Token.new(:right_paren, 1, 11),
        Token.new(:right_bracket, 1, 12),
        Token.new(:eof, 1, 13)
      ]

      expected =
        AST.list_literal([
          AST.binary_op(AST.integer(1), :plus, AST.integer(2)),
          # Assuming f() is f applied to hole
          AST.function_app(AST.identifier("f"), AST.hole())
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a list with a trailing comma" do
      # This is not supported!
      # Input: [1, 2,]
      input = [
        Token.new(:left_bracket, 1, 1),
        Token.new(:integer, 1, 1, 2),
        Token.new(:comma, 1, 3),
        Token.new(:integer, 2, 1, 4),
        Token.new(:comma, 1, 5),
        Token.new(:right_bracket, 1, 6),
        Token.new(:eof, 1, 7)
      ]

      # expected =
      #  AST.list_literal([
      #    AST.integer(1),
      #    AST.integer(2)
      #  ])

      expected = "Unexpected token at start of expression: right_bracket at 1:6"

      assert {:error, ^expected} = Parser.parse(input)
    end
  end

  describe "record literal expressions" do
    test "parses an empty record literal" do
      # Input: {}
      input = [
        Token.new(:left_brace, 1, 1),
        Token.new(:right_brace, 1, 2),
        Token.new(:eof, 1, 3)
      ]

      # Assuming a new AST node
      expected = AST.record_literal([])
      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a record with one field" do
      # Input: { a = 1 }
      Logger.info("Parsing: { a = 1 }")

      input = [
        Token.new(:left_brace, 1, 1),
        Token.new(:identifier, "a", 1, 3),
        Token.new(:equals, 1, 5),
        Token.new(:integer, 1, 1, 7),
        Token.new(:right_brace, 1, 18),
        Token.new(:eof, 1, 19)
      ]

      expected =
        AST.record_literal([
          # Assuming a new AST node
          AST.record_expression_field(AST.identifier("a"), AST.integer(1))
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a record with multiple fields" do
      # Input: { a = 1, b = "x" }
      input = [
        Token.new(:left_brace, 1, 1),
        Token.new(:identifier, "a", 1, 3),
        Token.new(:equals, 1, 5),
        Token.new(:integer, 1, 1, 7),
        Token.new(:comma, 1, 8),
        Token.new(:identifier, "b", 1, 10),
        Token.new(:equals, 1, 12),
        Token.new(:text, "x", 1, 14),
        Token.new(:right_brace, 1, 18),
        Token.new(:eof, 1, 19)
      ]

      expected =
        AST.record_literal([
          # Assuming a new AST node
          AST.record_expression_field(AST.identifier("a"), AST.integer(1)),
          AST.record_expression_field(AST.identifier("b"), AST.text("x"))
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a record with a spread expression" do
      # Input: { ..g, a = 2 }
      input = [
        Token.new(:left_brace, 1, 1),
        Token.new(:double_dot, 1, 3),
        Token.new(:identifier, "g", 1, 5),
        Token.new(:comma, 1, 6),
        Token.new(:identifier, "a", 1, 8),
        Token.new(:equals, 1, 10),
        Token.new(:integer, 2, 1, 12),
        Token.new(:right_brace, 1, 13),
        Token.new(:eof, 1, 14)
      ]

      expected =
        AST.record_literal([
          AST.spread_expression(AST.identifier("g")),
          AST.record_expression_field(AST.identifier("a"), AST.integer(2))
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a record with a reversed spread expression" do
      # Input: { a = 2, ..g }
      input = [
        Token.new(:left_brace, 1, 1),
        Token.new(:identifier, "a", 1, 8),
        Token.new(:equals, 1, 10),
        Token.new(:integer, 2, 1, 12),
        Token.new(:comma, 1, 6),
        Token.new(:double_dot, 1, 3),
        Token.new(:identifier, "g", 1, 5),
        Token.new(:right_brace, 1, 13),
        Token.new(:eof, 1, 14)
      ]

      expected =
        AST.record_literal([
          AST.record_expression_field(AST.identifier("a"), AST.integer(2)),
          AST.spread_expression(AST.identifier("g"))
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end

  test "parses a simple where-clause" do
    # Input: "x ; x = 1"
    input = [
      Token.new(:identifier, "x", 1, 1),
      Token.new(:semicolon, 1, 3),
      Token.new(:identifier, "x", 1, 5),
      Token.new(:equals, 1, 7),
      Token.new(:integer, 1, 1, 9),
      Token.new(:eof, 1, 10)
    ]

    # We need a new, more descriptive AST node.
    expected =
      AST.where(
        AST.identifier("x"),
        AST.binary_op(AST.identifier("x"), :equals, AST.integer(1))
      )

    assert {:ok, ^expected} = Parser.parse(input)
  end
end
