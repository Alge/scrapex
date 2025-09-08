defmodule Scrapex.ParserTest do
  use ExUnit.Case
  alias Scrapex.{Parser, AST, Token}

  @literal_cases [
    # Integers
    {:integer, 123, AST.integer(123)},
    {:integer, 0, AST.integer(0)},
    # Floats
    {:float, 1.0, AST.float(1.0)},
    {:float, 123.456, AST.float(123.456)},
    # Text
    {:text, "hello", AST.text("hello")},
    {:text, "", AST.text("")},
    # Interpolated Text
    {:interpolated_text, "hello `\"sweet\"` world",
     AST.interpolated_text("hello `\"sweet\"` world")},
    # Base64
    {:base64, "SGVsbG8=", AST.base64("SGVsbG8=")},
    # Hexbyte
    {:hexbyte, "FF", AST.hexbyte("FF")},
    {:hexbyte, "0A", AST.hexbyte("0A")},
    # Identifier
    {:identifier, "x", AST.identifier("x")},
    {:identifier, "abc-123", AST.identifier("abc-123")},
    # Hole
    {:hole, nil, AST.hole()}
    # Note: variant_literal tests might need a new token type in the lexer.
  ]

  for {token_type, token_value, expected_ast} <- @literal_cases do
    test "parses literal: #{token_type} with value #{inspect(token_value)}" do
      input = [
        Token.new(unquote(token_type), unquote(token_value), 1, 1),
        Token.new(:eof, 1, 2)
      ]

      expected_result = unquote(expected_ast)

      assert {:ok, result} = Parser.parse(input)
      assert result == expected_result
    end
  end

  test "parses a where-clause expression using a semicolon" do
    # Input represents "123; 456"
    input = [
      Token.new(:integer, 123, 1, 1),
      Token.new(:semicolon, 1, 4),
      Token.new(:identifier, "x", 1, 5),
      Token.new(:equals, 1, 4),
      Token.new(:integer, 456, 1, 5),
      Token.new(:eof, 1, 8)
    ]

    expected =
      AST.binary_op(
        AST.integer(123),
        :semicolon,
        AST.binary_op(
          AST.identifier("x"),
          :equals,
          AST.integer(456)
        )
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

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
end
