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

  test "parses a simple function application" do
    # Input represents "f x"
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:identifier, "x", 1, 3),
      Token.new(:eof, 1, 4)
    ]

    # The expected AST is a function_application node.
    # (You will need to add this node to your AST.Expression module)
    expected =
      AST.function_app(
        AST.identifier("f"),
        AST.identifier("x")
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses a simple function application with negated argument" do
    # Input represents "f x"
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:left_paren, 1, 3),
      Token.new(:minus, 1, 4),
      Token.new(:identifier, "x", 1, 5),
      Token.new(:right_paren, 1, 6),
      Token.new(:eof, 1, 7)
    ]

    # The expected AST is a function_application node.
    # (You will need to add this node to your AST.Expression module)
    expected =
      AST.function_app(
        AST.identifier("f"),
        AST.unary_op(:minus, AST.identifier("x"))
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses curried function application with three applications" do
    # Input represents "f x y z" which is ((f x) y) z
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:identifier, "x", 1, 3),
      Token.new(:identifier, "y", 1, 5),
      Token.new(:identifier, "z", 1, 7),
      Token.new(:eof, 1, 8)
    ]

    # ((f x) y) z - nested function applications, left-associative
    expected =
      AST.function_app(
        AST.function_app(
          # (f x)
          AST.function_app(AST.identifier("f"), AST.identifier("x")),
          # (f x) y
          AST.identifier("y")
        ),
        # ((f x) y) z
        AST.identifier("z")
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "function application binds tighter than addition" do
    # Input: "f x + y" should be "(f x) + y"
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:identifier, "x", 1, 3),
      Token.new(:plus, 1, 5),
      Token.new(:identifier, "y", 1, 7),
      Token.new(:eof, 1, 8)
    ]

    expected =
      AST.binary_op(
        AST.function_app(AST.identifier("f"), AST.identifier("x")),
        :plus,
        AST.identifier("y")
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "function application binds looser than dot operator" do
    # Input: "f x.y" should be "f (x.y)"
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:identifier, "x", 1, 3),
      Token.new(:dot, 1, 4),
      Token.new(:identifier, "y", 1, 5),
      Token.new(:eof, 1, 6)
    ]

    expected =
      AST.function_app(
        AST.identifier("f"),
        AST.binary_op(AST.identifier("x"), :dot, AST.identifier("y"))
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "function application is left associative" do
    # Input: "f g x" should be "(f g) x", not "f (g x)"
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:identifier, "g", 1, 3),
      Token.new(:identifier, "x", 1, 5),
      Token.new(:eof, 1, 6)
    ]

    expected =
      AST.function_app(
        AST.function_app(AST.identifier("f"), AST.identifier("g")),
        AST.identifier("x")
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "function application with parenthesized function expression" do
    # Input: "(f + g) x"
    input = [
      Token.new(:left_paren, 1, 1),
      Token.new(:identifier, "f", 1, 2),
      Token.new(:plus, 1, 4),
      Token.new(:identifier, "g", 1, 6),
      Token.new(:right_paren, 1, 7),
      Token.new(:identifier, "x", 1, 9),
      Token.new(:eof, 1, 10)
    ]

    expected =
      AST.function_app(
        AST.binary_op(AST.identifier("f"), :plus, AST.identifier("g")),
        AST.identifier("x")
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "function application with multiplication" do
    # Input: "f x * y" should be "(f x) * y"
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:identifier, "x", 1, 3),
      Token.new(:multiply, 1, 5),
      Token.new(:identifier, "y", 1, 7),
      Token.new(:eof, 1, 8)
    ]

    expected =
      AST.binary_op(
        AST.function_app(AST.identifier("f"), AST.identifier("x")),
        :multiply,
        AST.identifier("y")
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "function application with high-precedence unary operators" do
    # Input: "f !x" - the ! should bind to x, so f gets applied to (!x)
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:exclamation_mark, 1, 3),
      Token.new(:identifier, "x", 1, 4),
      Token.new(:eof, 1, 5)
    ]

    expected =
      AST.function_app(
        AST.identifier("f"),
        AST.unary_op(:exclamation_mark, AST.identifier("x"))
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "literal integer as function (should parse successfully)" do
    # Input: "123 x" - should parse as function_app(integer(123), identifier("x"))
    input = [
      Token.new(:integer, 123, 1, 1),
      Token.new(:identifier, "x", 1, 5),
      Token.new(:eof, 1, 6)
    ]

    expected = AST.function_app(AST.integer(123), AST.identifier("x"))

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "mixed function application and binary operators" do
    # Input: "f x + g y" should be "(f x) + (g y)"
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:identifier, "x", 1, 3),
      Token.new(:plus, 1, 5),
      Token.new(:identifier, "g", 1, 7),
      Token.new(:identifier, "y", 1, 9),
      Token.new(:eof, 1, 10)
    ]

    expected =
      AST.binary_op(
        AST.function_app(AST.identifier("f"), AST.identifier("x")),
        :plus,
        AST.function_app(AST.identifier("g"), AST.identifier("y"))
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "function application with parenthesized arguments" do
    # Input: "f (g x) (h y)"
    # Should be ((f (g x)) (h y)) - left associative
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:left_paren, 1, 3),
      Token.new(:identifier, "g", 1, 4),
      Token.new(:identifier, "x", 1, 6),
      Token.new(:right_paren, 1, 7),
      Token.new(:left_paren, 1, 9),
      Token.new(:identifier, "h", 1, 10),
      Token.new(:identifier, "y", 1, 12),
      Token.new(:right_paren, 1, 13),
      Token.new(:eof, 1, 14)
    ]

    expected =
      AST.function_app(
        AST.function_app(
          AST.identifier("f"),
          AST.function_app(AST.identifier("g"), AST.identifier("x"))
        ),
        AST.function_app(AST.identifier("h"), AST.identifier("y"))
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "function application with complex nested precedence" do
    # Input: "f x.y + z" should be "(f (x.y)) + z"
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:identifier, "x", 1, 3),
      Token.new(:dot, 1, 4),
      Token.new(:identifier, "y", 1, 5),
      Token.new(:plus, 1, 7),
      Token.new(:identifier, "z", 1, 9),
      Token.new(:eof, 1, 10)
    ]

    expected =
      AST.binary_op(
        AST.function_app(
          AST.identifier("f"),
          AST.binary_op(AST.identifier("x"), :dot, AST.identifier("y"))
        ),
        :plus,
        AST.identifier("z")
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "chained function applications with different argument types" do
    # Input: "f 123 'hello' x"
    # Should be (((f 123) 'hello') x)
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:integer, 123, 1, 3),
      Token.new(:text, "hello", 1, 7),
      Token.new(:identifier, "x", 1, 15),
      Token.new(:eof, 1, 16)
    ]

    expected =
      AST.function_app(
        AST.function_app(
          AST.function_app(AST.identifier("f"), AST.integer(123)),
          AST.text("hello")
        ),
        AST.identifier("x")
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end
end
