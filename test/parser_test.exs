defmodule Scrapex.ParserTest do
  use ExUnit.Case
  alias Scrapex.{Parser, AST, Token}

  test "parses a program with multiple expressions separated by semicolons" do
    # Input represents the code "123; 456"
    input = [
      Token.new(:integer, 123, 1, 1),
      Token.new(:semicolon, 1, 4),
      Token.new(:integer, 456, 1, 5),
      Token.new(:eof, 1, 8)
    ]

    # The final AST should be a single Program node containing a
    # list of the two integer expressions.
    expected =
      AST.program([
        AST.integer(123),
        AST.integer(456)
      ])

    assert {:ok, result} = Parser.parse_program(input)
    assert result == expected
  end

  test "parses a program ending with multiple semicolons" do
    # Input represents the code "123;;;;;"
    input = [
      Token.new(:integer, 123, 1, 1),
      Token.new(:semicolon, 1, 4),
      Token.new(:semicolon, 1, 4),
      Token.new(:semicolon, 1, 4),
      Token.new(:eof, 1, 8)
    ]

    # The final AST should be a single Program node containing a
    # list of the two integer expressions.
    expected =
      AST.program([
        AST.integer(123)
      ])

    assert {:ok, result} = Parser.parse_program(input)
    assert result == expected
  end

  @literal_cases [
    # Integers
    {:integer, 123, AST.integer(123)},
    {:integer, 0, AST.integer(0)},

    # # Floats
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
  ]

  for {token_type, token_value, expected_ast} <- @literal_cases do
    test "parses literal: #{token_type} with value #{inspect(token_value)}" do
      input = [
        Token.new(unquote(token_type), unquote(token_value), 1, 1),
        Token.new(:eof, 1, 2)
      ]

      expected_program_ast = AST.program([unquote(expected_ast)])

      assert {:ok, result} = Parser.parse_program(input),
             "Failed to parse token: #{unquote(token_type)}"

      assert result == expected_program_ast,
             "Incorrect AST for token: #{unquote(token_type)}"
    end
  end
end
