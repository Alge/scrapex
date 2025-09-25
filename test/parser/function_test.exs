defmodule Scrapex.ParserTest.Functions do
  use ExUnit.Case, async: true

  alias Scrapex.{AST, Parser, Token}

  # =============================================================================
  # Function Application
  # =============================================================================

  describe "Function Application" do
    test "parses a simple function application" do
      # Input: "f x"
      input = [
        Token.new(:identifier, "f", 1, 1),
        Token.new(:identifier, "x", 1, 3),
        Token.new(:eof, 1, 4)
      ]

      expected =
        AST.function_app(
          AST.identifier("f"),
          AST.identifier("x")
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a function application with a negated argument" do
      # Input: "f (-x)"
      input = [
        Token.new(:identifier, "f", 1, 1),
        Token.new(:left_paren, 1, 3),
        Token.new(:minus, 1, 4),
        Token.new(:identifier, "x", 1, 5),
        Token.new(:right_paren, 1, 6),
        Token.new(:eof, 1, 7)
      ]

      expected =
        AST.function_app(
          AST.identifier("f"),
          AST.unary_op(:minus, AST.identifier("x"))
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses curried function application" do
      # Input: "f x y z" should be parsed left-associatively as (((f x) y) z)
      input = [
        Token.new(:identifier, "f", 1, 1),
        Token.new(:identifier, "x", 1, 3),
        Token.new(:identifier, "y", 1, 5),
        Token.new(:identifier, "z", 1, 7),
        Token.new(:eof, 1, 8)
      ]

      expected =
        AST.function_app(
          AST.function_app(
            AST.function_app(AST.identifier("f"), AST.identifier("x")),
            AST.identifier("y")
          ),
          AST.identifier("z")
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "function application binds tighter than addition" do
      # Input: "f x + y" should be parsed as "(f x) + y"
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

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "function application binds tighter than multiplication" do
      # Input: "f x * y" should be parsed as "(f x) * y"
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

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "function application binds looser than dot operator" do
      # Input: "f x.y" should be parsed as "f (x.y)"
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
          AST.field_access(AST.identifier("x"), "y")
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "function application is left associative" do
      # Input: "f g x" should be parsed as "(f g) x", not "f (g x)"
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

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "application with a parenthesized function expression" do
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

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "application argument can be a high-precedence unary operation" do
      # Input: "f !x" should be parsed as "f (!x)"
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

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "a literal can be in the function position" do
      # Input: "123 x" should parse, even if it fails at evaluation.
      input = [
        Token.new(:integer, 123, 1, 1),
        Token.new(:identifier, "x", 1, 5),
        Token.new(:eof, 1, 6)
      ]

      expected = AST.function_app(AST.integer(123), AST.identifier("x"))

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "mixed application and binary operators" do
      # Input: "f x + g y" should be parsed as "(f x) + (g y)"
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

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "application with parenthesized arguments" do
      # Input: "f (g x) (h y)" should be parsed as "((f (g x)) (h y))"
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

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end

  # =============================================================================
  # Pattern Match Expressions
  # =============================================================================
  describe "Pattern Match Expressions" do
    test "parses a binding to a multi-clause pattern match" do
      # This is the canonical test for a function defined by pattern matching.
      # Input: "f; f = | 1 -> 2 | 2 -> \"hello\""
      input = [
        Token.new(:identifier, "f", 1, 1),
        Token.new(:semicolon, 1, 2),
        Token.new(:identifier, "f", 1, 4),
        Token.new(:equals, 1, 6),
        Token.new(:pipe, 1, 8),
        Token.new(:integer, 1, 1, 10),
        Token.new(:right_arrow, 1, 12),
        Token.new(:integer, 2, 1, 15),
        Token.new(:pipe, 1, 17),
        Token.new(:integer, 2, 1, 19),
        Token.new(:right_arrow, 1, 21),
        Token.new(:text, "hello", 1, 24),
        Token.new(:eof, 1, 31)
      ]

      expected =
        AST.where(
          AST.identifier("f"),
          AST.binding(
            "f",
            AST.pattern_match_expression([
              AST.pattern_clause(AST.integer(1), AST.integer(2)),
              AST.pattern_clause(AST.integer(2), AST.text("hello"))
            ])
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a multi-clause pattern match ending with a catch-all" do
      # Verifies a common use case with a final wildcard pattern.
      # Input: "f; f = | 1 -> 2 | _ -> 99"
      input = [
        Token.new(:identifier, "f", 1, 1),
        Token.new(:semicolon, 1, 2),
        Token.new(:identifier, "f", 1, 4),
        Token.new(:equals, 1, 6),
        Token.new(:pipe, 1, 8),
        Token.new(:integer, 1, 1, 10),
        Token.new(:right_arrow, 1, 12),
        Token.new(:integer, 2, 1, 15),
        Token.new(:pipe, 1, 17),
        Token.new(:underscore, 1, 19),
        Token.new(:right_arrow, 1, 21),
        Token.new(:integer, 99, 1, 24),
        Token.new(:eof, 1, 26)
      ]

      expected =
        AST.where(
          AST.identifier("f"),
          AST.binding(
            "f",
            AST.pattern_match_expression([
              AST.pattern_clause(AST.integer(1), AST.integer(2)),
              AST.pattern_clause(AST.wildcard(), AST.integer(99))
            ])
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end

  # =============================================================================
  # Lambda Expressions (desugared to Pattern Match Expressions)
  # =============================================================================
  describe "Lambda Expressions" do
    test "parses a lambda as a single-clause pattern match" do
      # Tests that "x -> x" is desugared into "| x -> x"
      input = [
        Token.new(:identifier, "x", 1, 1),
        Token.new(:right_arrow, 1, 3),
        Token.new(:identifier, "x", 1, 6),
        Token.new(:eof, 1, 7)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.identifier("x"), AST.identifier("x"))
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a lambda with a complex expression body" do
      # Tests that "val -> val * 2 + 1" is correctly desugared.
      input = [
        Token.new(:identifier, "val", 1, 1),
        Token.new(:right_arrow, 1, 5),
        Token.new(:identifier, "val", 1, 8),
        Token.new(:multiply, 1, 12),
        Token.new(:integer, 2, 1, 14),
        Token.new(:plus, 1, 16),
        Token.new(:integer, 1, 1, 18),
        Token.new(:eof, 1, 19)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("val"),
            AST.binary_op(
              AST.binary_op(AST.identifier("val"), :multiply, AST.integer(2)),
              :plus,
              AST.integer(1)
            )
          )
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a curried function as nested pattern matches" do
      # Input: "a -> b -> a + b" should be desugared into "| a -> (| b -> a + b)"
      input = [
        Token.new(:identifier, "a", 1, 1),
        Token.new(:right_arrow, 1, 3),
        Token.new(:identifier, "b", 1, 6),
        Token.new(:right_arrow, 1, 8),
        Token.new(:identifier, "a", 1, 11),
        Token.new(:plus, 1, 13),
        Token.new(:identifier, "b", 1, 15),
        Token.new(:eof, 1, 16)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("a"),
            AST.pattern_match_expression([
              AST.pattern_clause(
                AST.identifier("b"),
                AST.binary_op(AST.identifier("a"), :plus, AST.identifier("b"))
              )
            ])
          )
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses an immediately invoked function expression (IIFE)" do
      # Input: "(x -> x + 1) 5"
      input = [
        Token.new(:left_paren, 1, 1),
        Token.new(:identifier, "x", 1, 2),
        Token.new(:right_arrow, 1, 4),
        Token.new(:identifier, "x", 1, 7),
        Token.new(:plus, 1, 9),
        Token.new(:integer, 1, 1, 11),
        Token.new(:right_paren, 1, 12),
        Token.new(:integer, 5, 1, 14),
        Token.new(:eof, 1, 15)
      ]

      expected =
        AST.function_app(
          AST.pattern_match_expression([
            AST.pattern_clause(
              AST.identifier("x"),
              AST.binary_op(AST.identifier("x"), :plus, AST.integer(1))
            )
          ]),
          AST.integer(5)
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end

  # =============================================================================
  # Function Bindings
  # =============================================================================
  describe "Function Bindings" do
    test "parses a binding of a name to a lambda" do
      # Input: "identity; identity = x -> x"
      input = [
        Token.new(:identifier, "identity", 1, 1),
        Token.new(:semicolon, 1, 8),
        Token.new(:identifier, "identity", 1, 10),
        Token.new(:equals, 1, 19),
        Token.new(:identifier, "x", 1, 21),
        Token.new(:right_arrow, 1, 23),
        Token.new(:identifier, "x", 1, 26),
        Token.new(:eof, 1, 27)
      ]

      expected =
        AST.where(
          AST.identifier("identity"),
          AST.binding(
            "identity",
            AST.pattern_match_expression([
              AST.pattern_clause(AST.identifier("x"), AST.identifier("x"))
            ])
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a function binding inside a where clause" do
      # Input: "addone 1; addone = a -> a + 1"
      input = [
        Token.new(:identifier, "addone", 1, 1),
        Token.new(:integer, 1, 1, 8),
        Token.new(:semicolon, 1, 9),
        Token.new(:identifier, "addone", 1, 11),
        Token.new(:equals, 1, 18),
        Token.new(:identifier, "a", 1, 20),
        Token.new(:right_arrow, 1, 22),
        Token.new(:identifier, "a", 1, 25),
        Token.new(:plus, 1, 27),
        Token.new(:integer, 1, 1, 29),
        Token.new(:eof, 2, 1)
      ]

      expected =
        AST.where(
          AST.function_app(AST.identifier("addone"), AST.integer(1)),
          AST.binding(
            "addone",
            AST.pattern_match_expression([
              AST.pattern_clause(
                AST.identifier("a"),
                AST.binary_op(AST.identifier("a"), :plus, AST.integer(1))
              )
            ])
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a lambda whose body contains a where clause" do
      # Input: "add_y; add_y = x -> x + y; y = 10"
      input = [
        Token.new(:identifier, "add_y", 1, 1),
        Token.new(:semicolon, 1, 7),
        Token.new(:identifier, "add_y", 1, 9),
        Token.new(:equals, 1, 15),
        Token.new(:identifier, "x", 1, 17),
        Token.new(:right_arrow, 1, 19),
        Token.new(:identifier, "x", 1, 22),
        Token.new(:plus, 1, 24),
        Token.new(:identifier, "y", 1, 26),
        Token.new(:semicolon, 1, 27),
        Token.new(:identifier, "y", 1, 29),
        Token.new(:equals, 1, 31),
        Token.new(:integer, 10, 1, 33),
        Token.new(:eof, 1, 35)
      ]

      expected =
        AST.where(
          AST.identifier("add_y"),
          AST.binding(
            "add_y",
            AST.pattern_match_expression([
              AST.pattern_clause(
                AST.identifier("x"),
                AST.where(
                  AST.binary_op(AST.identifier("x"), :plus, AST.identifier("y")),
                  AST.binding("y", AST.integer(10))
                )
              )
            ])
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end

  # =============================================================================
  # Patterns as Parameters
  # =============================================================================
  describe "Patterns as Parameters" do
    test "parses a lambda with a wildcard pattern as a parameter" do
      # Input: "_ -> 42"
      input = [
        Token.new(:underscore, 1, 1),
        Token.new(:right_arrow, 1, 3),
        Token.new(:integer, 42, 1, 6),
        Token.new(:eof, 1, 8)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.wildcard(), AST.integer(42))
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a lambda with a list pattern as a parameter" do
      # Input: "is_empty; is_empty = | [] -> #true"
      input = [
        Token.new(:identifier, "is_empty", 1, 1),
        Token.new(:semicolon, 1, 10),
        Token.new(:identifier, "is_empty", 1, 12),
        Token.new(:equals, 1, 21),
        Token.new(:pipe, 1, 23),
        Token.new(:left_bracket, 1, 25),
        Token.new(:right_bracket, 1, 26),
        Token.new(:right_arrow, 1, 28),
        Token.new(:hashtag, 1, 31),
        Token.new(:identifier, "true", 1, 32),
        Token.new(:eof, 1, 36)
      ]

      expected =
        AST.where(
          AST.identifier("is_empty"),
          AST.binding(
            "is_empty",
            AST.pattern_match_expression([
              AST.pattern_clause(
                AST.empty_list(),
                AST.variant("true")
              )
            ])
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a pattern match clause that returns a lambda" do
      # Input: "f; f = | a -> b -> a + b"
      input = [
        Token.new(:identifier, "f", 1, 1),
        Token.new(:semicolon, 1, 2),
        Token.new(:identifier, "f", 1, 4),
        Token.new(:equals, 1, 6),
        Token.new(:pipe, 1, 8),
        Token.new(:identifier, "a", 1, 10),
        Token.new(:right_arrow, 1, 12),
        Token.new(:identifier, "b", 1, 15),
        Token.new(:right_arrow, 1, 17),
        Token.new(:identifier, "a", 1, 20),
        Token.new(:plus, 1, 22),
        Token.new(:identifier, "b", 1, 24),
        Token.new(:eof, 1, 25)
      ]

      expected =
        AST.where(
          AST.identifier("f"),
          AST.binding(
            "f",
            AST.pattern_match_expression([
              AST.pattern_clause(
                AST.identifier("a"),
                AST.pattern_match_expression([
                  AST.pattern_clause(
                    AST.identifier("b"),
                    AST.binary_op(AST.identifier("a"), :plus, AST.identifier("b"))
                  )
                ])
              )
            ])
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end

  test "function application with list literal argument" do
    # Input: "f [1, 2]"
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:left_bracket, 1, 3),
      Token.new(:integer, 1, 1, 4),
      Token.new(:comma, 1, 5),
      Token.new(:integer, 2, 1, 7),
      Token.new(:right_bracket, 1, 8),
      Token.new(:eof, 1, 9)
    ]

    expected =
      AST.function_app(
        AST.identifier("f"),
        AST.list_literal([AST.integer(1), AST.integer(2)])
      )

    assert {:ok, ^expected} = Parser.parse(input)
  end

  test "function application with record literal argument" do
    # Input: "f {a = 1}"
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:left_brace, 1, 3),
      Token.new(:identifier, "a", 1, 4),
      Token.new(:equals, 1, 6),
      Token.new(:integer, 1, 1, 8),
      Token.new(:right_brace, 1, 9),
      Token.new(:eof, 1, 10)
    ]

    expected =
      AST.function_app(
        AST.identifier("f"),
        AST.record_literal([
          AST.record_expression_field("a", AST.integer(1))
        ])
      )

    assert {:ok, ^expected} = Parser.parse(input)
  end
end
