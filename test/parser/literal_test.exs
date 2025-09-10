defmodule Scrapex.ParserTest.Literals do
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
    {:identifier, "abc-123", AST.identifier("abc-123")}
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
end
