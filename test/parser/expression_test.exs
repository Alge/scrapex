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
          AST.record_expression_field("a", AST.integer(1))
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
          AST.record_expression_field("a", AST.integer(1)),
          AST.record_expression_field("b", AST.text("x"))
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
          AST.record_expression_field("a", AST.integer(2))
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
          AST.record_expression_field("a", AST.integer(2)),
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
        AST.binding("x", AST.integer(1))
      )

    assert {:ok, ^expected} = Parser.parse(input)
  end

  test "parses chained where-clauses with correct right-associativity" do
    # Input: "a + b ; a = 1 ; b = 2"
    # This should be parsed as: (a + b) ; (a = 1 ; b = 2)
    input = [
      Token.new(:identifier, "a", 1, 1),
      Token.new(:plus, 1, 3),
      Token.new(:identifier, "b", 1, 5),
      Token.new(:semicolon, 1, 7),
      Token.new(:identifier, "a", 1, 9),
      Token.new(:equals, 1, 11),
      Token.new(:integer, 1, 1, 13),
      Token.new(:semicolon, 1, 15),
      Token.new(:identifier, "b", 1, 17),
      Token.new(:equals, 1, 19),
      Token.new(:integer, 2, 1, 21),
      Token.new(:eof, 1, 22)
    ]

    expected =
      AST.where(
        AST.binary_op(AST.identifier("a"), :plus, AST.identifier("b")),
        AST.where(
          AST.binding("a", AST.integer(1)),
          AST.binding("b", AST.integer(2))
        )
      )

    assert {:ok, ^expected} = Parser.parse(input)
  end

  test "parses a standalone wildcard expression" do
    # This is the most fundamental test to prove the parser can begin an
    # expression with a wildcard. It isolates the `parse_prefix` logic.
    # Input: "_"
    input = [
      Token.new(:underscore, nil, 1, 1),
      Token.new(:eof, 1, 2)
    ]

    expected = AST.wildcard()

    assert {:ok, ^expected} = Parser.parse(input)
  end

  test "parses single variant as atomic literal in expression context" do
    # Input: "#true"
    input = [
      Token.new(:hashtag, 1, 1),
      Token.new(:identifier, "true", 1, 2),
      Token.new(:eof, 1, 6)
    ]

    # Should be atomic variant, not wrapped in type_union
    expected = AST.variant("true")

    assert {:ok, ^expected} = Parser.parse(input)
  end

  test "parses a pattern match expression with a wildcard pattern" do
    # Input: "my_func; my_func = | _ -> #ok"
    input = [
      Token.new(:identifier, "my_func", 1, 1),
      Token.new(:semicolon, 1, 9),
      Token.new(:identifier, "my_func", 2, 1),
      Token.new(:equals, 2, 9),
      Token.new(:pipe, 2, 11),
      Token.new(:underscore, 2, 13),
      Token.new(:right_arrow, 2, 15),
      Token.new(:hashtag, 2, 18),
      Token.new(:identifier, "ok", 2, 19),
      Token.new(:eof, 2, 21)
    ]

    expected =
      AST.where(
        AST.identifier("my_func"),
        AST.binding(
          "my_func",
          AST.pattern_match_expression([
            AST.pattern_clause(
              AST.wildcard(),
              AST.variant("ok")
            )
          ])
        )
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses a full pattern match function in a where clause" do
    # Input:
    # f ; f =
    # | #exact-change -> #ok #chips
    # | #credit-card -> #err "Credit card reader is broken."
    # | _ -> #err "Invalid payment method."
    input = [
      Token.new(:identifier, "f", 1, 1),
      Token.new(:semicolon, 1, 3),
      Token.new(:identifier, "f", 1, 5),
      Token.new(:equals, 1, 7),
      Token.new(:pipe, 2, 3),
      Token.new(:hashtag, 2, 5),
      Token.new(:identifier, "exact-change", 2, 6),
      Token.new(:right_arrow, 2, 19),
      Token.new(:hashtag, 2, 22),
      Token.new(:identifier, "ok", 2, 23),
      Token.new(:hashtag, 2, 26),
      Token.new(:identifier, "chips", 2, 27),
      Token.new(:pipe, 3, 3),
      Token.new(:hashtag, 3, 5),
      Token.new(:identifier, "credit-card", 3, 6),
      Token.new(:right_arrow, 3, 18),
      Token.new(:hashtag, 3, 21),
      Token.new(:identifier, "err", 3, 22),
      Token.new(:text, "Credit card reader is broken.", 3, 26),
      Token.new(:pipe, 4, 3),
      Token.new(:underscore, 4, 5),
      Token.new(:right_arrow, 4, 7),
      Token.new(:hashtag, 4, 10),
      Token.new(:identifier, "err", 4, 11),
      Token.new(:text, "Invalid payment method.", 4, 15),
      Token.new(:eof, 4, 40)
    ]

    expected =
      AST.where(
        AST.identifier("f"),
        AST.binding(
          "f",
          AST.pattern_match_expression([
            AST.pattern_clause(
              AST.variant_pattern(AST.identifier("exact-change"), []),
              # FIXED: #ok #chips is a variant with a variant payload
              AST.variant("ok", AST.variant("chips", AST.hole()))
            ),
            AST.pattern_clause(
              AST.variant_pattern(AST.identifier("credit-card"), []),
              # FIXED: #err "text" is a variant with text payload
              AST.variant("err", AST.text("Credit card reader is broken."))
            ),
            AST.pattern_clause(
              AST.wildcard(),
              # FIXED: #err "text" is a variant with text payload
              AST.variant("err", AST.text("Invalid payment method."))
            )
          ])
        )
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "stops parsing a clause body at a semicolon" do
    # This code demonstrates the bug. The parser should parse `| _ -> 1`
    # and treat the `; x = 2` as a separate, following statement.
    # The bug causes it to parse the body as `1 ; x = 2`.
    # Input: "main ; f = | _ -> 1 ; x = 2"
    input = [
      Token.new(:identifier, "main", 1, 1),
      Token.new(:semicolon, 1, 6),
      Token.new(:identifier, "f", 1, 8),
      Token.new(:equals, 1, 10),
      Token.new(:pipe, 1, 12),
      Token.new(:underscore, 1, 14),
      Token.new(:right_arrow, 1, 16),
      Token.new(:integer, 1, 1, 18),
      Token.new(:semicolon, 1, 20),
      Token.new(:identifier, "x", 1, 22),
      Token.new(:equals, 1, 24),
      Token.new(:integer, 2, 1, 26),
      Token.new(:eof, 1, 27)
    ]

    # The CORRECT AST has the `where` for `x=2` attached to the `where` for `f=...`,
    # NOT inside the pattern clause's body.
    expected =
      AST.where(
        AST.identifier("main"),
        AST.where(
          AST.binding(
            "f",
            AST.pattern_match_expression([
              AST.pattern_clause(
                AST.wildcard(),
                # The body should ONLY be the integer 1.
                AST.integer(1)
              )
            ])
          ),
          AST.binding("x", AST.integer(2))
        )
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end
end
