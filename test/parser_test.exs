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

    expected =
      AST.binary_op(
        AST.expression(AST.integer(123), nil),
        :semicolon,
        AST.expression(AST.integer(456), nil)
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  # test "parses a program ending with multiple semicolons" do
  #   # Input represents the code "123;;;;;"
  #   input = [
  #     Token.new(:integer, 123, 1, 1),
  #     Token.new(:semicolon, 1, 4),
  #     Token.new(:semicolon, 1, 4),
  #     Token.new(:semicolon, 1, 4),
  #     Token.new(:eof, 1, 8)
  #   ]

  #   # # The final AST should be a single Program node containing a
  #   # # list of the two integer expressions.
  #   # expected =
  #   #   AST.program([
  #   #     AST.expression(AST.integer(123), nil)
  #   #   ])

  #   # assert {:ok, result} = Parser.parse_program(input)
  #   # assert result == expected
  #   assert {:error, _reason} = Parser.parse_program(input)

  # end

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

      expected_result= AST.expression(unquote(expected_ast), nil)


      assert {:ok, result} = Parser.parse(input),
             "Failed to parse token: #{unquote(token_type)}"

      assert result == expected_result,
             "Incorrect AST for token: #{unquote(token_type)}"
    end
  end

  test "parses a simple binary expression with plus" do
    # Input represents the code "1 + 2"
    input = [
      Token.new(:integer, 1, 1, 1),
      Token.new(:plus, 1, 3),
      Token.new(:integer, 2, 1, 5),
      Token.new(:eof, 1, 6)
    ]

    lhs = AST.expression(AST.integer(1), nil)
    rhs = AST.expression(AST.integer(2), nil)
    infix_operation = AST.infix_operation(:plus, rhs)

    expected_expression = AST.expression(lhs, infix_operation)

    assert {:ok, result} = Parser.parse(input)
    assert result == expected_expression

  end


  # test "parses an expression with parentheses to override precedence" do
  #   # Input represents the code "(1 + 2) * 3"
  #   input = [
  #     Token.new(:left_paren, 1, 1),
  #     Token.new(:integer, 1, 1, 2),
  #     Token.new(:plus, 1, 4),
  #     Token.new(:integer, 2, 1, 6),
  #     Token.new(:right_paren, 1, 7),
  #     Token.new(:multiply, 1, 9),
  #     Token.new(:integer, 3, 1, 11),
  #     Token.new(:eof, 1, 12)
  #   ]

  #   # The expected AST should group the `1 + 2` expression as the
  #   # left-hand side of the multiplication.
  #   expected =
  #     AST.program([
  #       AST.binary_op(
  #         # The left side is the result of "1 + 2"
  #         AST.binary_op(AST.integer(1), :+, AST.integer(2)),
  #         # The operator is "*"
  #         :multiply,
  #         # The right side is just "3"
  #         AST.integer(3)
  #       )
  #     ])

  #   assert {:ok, result} = Parser.parse_program(input)
  #   assert result == expected
  # end

end
