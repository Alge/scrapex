# test/parser/pattern_test.exs

require Logger

defmodule Scrapex.Parser.PatternTest do
  use ExUnit.Case, async: true

  alias Scrapex.{Parser, Token}
  alias Scrapex.AST

  describe "pattern matching expressions" do
    test "parses a single, minimal pattern match clause" do
      # Input: | x -> 1
      input = [
        Token.new(:pipe, 1, 1),
        Token.new(:identifier, "x", 1, 3),
        Token.new(:right_arrow, 1, 5),
        Token.new(:integer, 1, 1, 7),
        Token.new(:eof, 1, 8)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.identifier("x"), AST.integer(1))
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a standalone pattern match expression with literals" do
      # | "a" -> 1 | "b" -> 2
      input = [
        Token.new(:pipe, 1, 1),
        Token.new(:text, "a", 1, 3),
        Token.new(:right_arrow, 1, 7),
        Token.new(:integer, 1, 1, 9),
        Token.new(:pipe, 1, 11),
        Token.new(:text, "b", 1, 13),
        Token.new(:right_arrow, 1, 17),
        Token.new(:integer, 2, 1, 19),
        Token.new(:eof, 1, 20)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.text("a"), AST.integer(1)),
          AST.pattern_clause(AST.text("b"), AST.integer(2))
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a pattern match assigned to a variable" do
      # f ; f = | x -> x
      input = [
        Token.new(:identifier, "f", 1, 1),
        Token.new(:semicolon, 1, 3),
        Token.new(:identifier, "f", 1, 5),
        Token.new(:equals, 1, 7),
        Token.new(:pipe, 1, 9),
        Token.new(:identifier, "x", 1, 11),
        Token.new(:right_arrow, 1, 13),
        Token.new(:identifier, "x", 1, 15),
        Token.new(:eof, 1, 16)
      ]

      expected =
        AST.binary_op(
          AST.identifier("f"),
          :semicolon,
          AST.binary_op(
            AST.identifier("f"),
            :equals,
            AST.pattern_match_expression([
              AST.pattern_clause(AST.identifier("x"), AST.identifier("x"))
            ])
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses wildcard and variable binding patterns" do
      # | _ -> 0 | n -> n
      input = [
        Token.new(:pipe, 1, 1),
        # Assuming the lexer produces :identifier for _
        Token.new(:underscore, nil, 1, 3),
        Token.new(:right_arrow, 1, 5),
        Token.new(:integer, 0, 1, 7),
        Token.new(:pipe, 1, 9),
        Token.new(:identifier, "n", 1, 11),
        Token.new(:right_arrow, 1, 13),
        Token.new(:identifier, "n", 1, 15),
        Token.new(:eof, 1, 16)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.wildcard(), AST.integer(0)),
          AST.pattern_clause(AST.identifier("n"), AST.identifier("n"))
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a pattern match with an empty list pattern" do
      # Input: | [] -> 0
      input = [
        Token.new(:pipe, 1, 1),
        Token.new(:left_bracket, 1, 3),
        Token.new(:right_bracket, 1, 4),
        Token.new(:right_arrow, 1, 6),
        Token.new(:integer, 0, 1, 8),
        Token.new(:eof, 1, 9)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.empty_list(), AST.integer(0))
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a pattern with a single-element list" do
      # Input: | [x] -> 1
      input = [
        Token.new(:pipe, 1, 1),
        Token.new(:left_bracket, 1, 3),
        Token.new(:identifier, "x", 1, 4),
        Token.new(:right_bracket, 1, 5),
        Token.new(:right_arrow, 1, 7),
        Token.new(:integer, 1, 1, 9),
        Token.new(:eof, 1, 10)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([AST.identifier("x")]),
            AST.integer(1)
          )
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a list pattern containing a wildcard" do
      # Input: | [_] -> 1
      input = [
        Token.new(:pipe, 1, 1),
        Token.new(:left_bracket, 1, 3),
        Token.new(:underscore, nil, 1, 4),
        Token.new(:right_bracket, 1, 5),
        Token.new(:right_arrow, 1, 7),
        Token.new(:integer, 1, 1, 9),
        Token.new(:eof, 1, 10)
      ]

      Logger.info("Parsing list pattern with wildcard")

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([AST.wildcard()]),
            AST.integer(1)
          )
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a pattern match with an empty record pattern" do
      # Input: | {} -> 0
      input = [
        Token.new(:pipe, 1, 1),
        Token.new(:left_brace, 1, 3),
        Token.new(:right_brace, 1, 4),
        Token.new(:right_arrow, 1, 6),
        Token.new(:integer, 0, 1, 8),
        Token.new(:eof, 1, 9)
      ]

      # This assumes you have the AST.Record module refactoring in place.
      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.record_pattern([]), AST.integer(0))
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a record pattern with one field" do
      # Input: | {a = 1} -> "one"
      input = [
        Token.new(:pipe, 1, 1),
        Token.new(:left_brace, 1, 3),
        Token.new(:identifier, "a", 1, 4),
        Token.new(:equals, 1, 5),
        Token.new(:integer, 1, 1, 6),
        Token.new(:right_brace, 1, 7),
        Token.new(:right_arrow, 1, 9),
        Token.new(:text, "one", 1, 11),
        Token.new(:eof, 1, 16)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.record_pattern([
              AST.record_expression_field(AST.identifier("a"), AST.integer(1))
            ]),
            AST.text("one")
          )
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    @tag :skip
    test "parses various list patterns" do
      # | [] -> 0 | [x, y] -> 1 | h >+ t -> 2 | [x,y] ++ t -> 3
      input = [
        Token.new(:pipe, 1, 1),
        Token.new(:left_bracket, 1, 3),
        Token.new(:right_bracket, 1, 4),
        Token.new(:right_arrow, 1, 6),
        Token.new(:integer, 0, 1, 8),
        Token.new(:pipe, 1, 10),
        Token.new(:left_bracket, 1, 12),
        Token.new(:identifier, "x", 1, 13),
        Token.new(:comma, 1, 14),
        Token.new(:identifier, "y", 1, 15),
        Token.new(:right_bracket, 1, 16),
        Token.new(:right_arrow, 1, 18),
        Token.new(:integer, 1, 1, 20),
        Token.new(:pipe, 1, 22),
        Token.new(:identifier, "h", 1, 24),
        Token.new(:cons, 1, 26),
        Token.new(:identifier, "t", 1, 29),
        Token.new(:right_arrow, 1, 31),
        Token.new(:integer, 2, 1, 33),
        Token.new(:pipe, 1, 35),
        Token.new(:left_bracket, 1, 37),
        Token.new(:identifier, "x", 1, 38),
        Token.new(:comma, 1, 39),
        Token.new(:identifier, "y", 1, 40),
        Token.new(:right_bracket, 1, 41),
        Token.new(:double_plus, 1, 43),
        Token.new(:identifier, "t", 1, 46),
        Token.new(:right_arrow, 1, 48),
        Token.new(:integer, 3, 1, 50),
        Token.new(:eof, 1, 51)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.empty_list(), AST.integer(0)),
          AST.pattern_clause(
            AST.regular_list_pattern([AST.identifier("x"), AST.identifier("y")]),
            AST.integer(1)
          ),
          AST.pattern_clause(
            AST.cons_list_pattern(AST.identifier("h"), AST.identifier("t")),
            AST.integer(2)
          ),
          AST.pattern_clause(
            AST.concat_list_pattern(
              [AST.identifier("x"), AST.identifier("y")],
              AST.identifier("t")
            ),
            AST.integer(3)
          )
        ])

      Logger.info("Trying to match")
      Logger.info(inspect(input))
      Logger.info("With:")
      Logger.info(inspect(expected))

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a pattern with multiple elements" do
      # Input: | [x, y] -> 1
      input = [
        Token.new(:pipe, 1, 1),
        Token.new(:left_bracket, 1, 3),
        Token.new(:identifier, "x", 1, 4),
        Token.new(:comma, 1, 5),
        Token.new(:identifier, "y", 1, 6),
        Token.new(:right_bracket, 1, 7),
        Token.new(:right_arrow, 1, 9),
        Token.new(:integer, 1, 1, 11),
        Token.new(:eof, 1, 12)
      ]

      expected =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.regular_list_pattern([AST.identifier("x"), AST.identifier("y")]),
            AST.integer(1)
          )
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    # @tag :skip
    # test "parses record patterns" do
    #   # | {a=1, b=x} -> x | {..r, a=1} -> r
    #   input = [
    #     Token.new(:pipe, 1, 1),
    #     Token.new(:left_brace, 1, 3),
    #     Token.new(:identifier, "a", 1, 4),
    #     Token.new(:equals, 1, 5),
    #     Token.new(:integer, 1, 1, 6),
    #     Token.new(:comma, 1, 7),
    #     Token.new(:identifier, "b", 1, 9),
    #     Token.new(:equals, 1, 10),
    #     Token.new(:identifier, "x", 1, 11),
    #     Token.new(:right_brace, 1, 12),
    #     Token.new(:right_arrow, 1, 14),
    #     Token.new(:identifier, "x", 1, 16),
    #     Token.new(:pipe, 1, 18),
    #     Token.new(:left_brace, 1, 20),
    #     Token.new(:double_dot, 1, 21),
    #     Token.new(:identifier, "r", 1, 23),
    #     Token.new(:comma, 1, 24),
    #     Token.new(:identifier, "a", 1, 26),
    #     Token.new(:equals, 1, 27),
    #     Token.new(:integer, 1, 1, 28),
    #     Token.new(:right_brace, 1, 29),
    #     Token.new(:right_arrow, 1, 31),
    #     Token.new(:identifier, "r", 1, 33),
    #     Token.new(:eof, 1, 34)
    #   ]

    #   expected =
    #     AST.pattern_match_expression([
    #       {
    #         AST.record_pattern([
    #           AST.record_pattern_field("a", AST.integer(1)),
    #           AST.record_pattern_field("b", AST.identifier("x"))
    #         ]),
    #         AST.identifier("x")
    #       },
    #       {
    #         AST.record_pattern([
    #           AST.rest(AST.identifier("r")),
    #           AST.record_pattern_field("a", AST.integer(1))
    #         ]),
    #         AST.identifier("r")
    #       }
    #     ])

    #   assert {:ok, ^expected} = Parser.parse(input)
    # end

    # @tag :skip
    # test "parses nested and text patterns" do
    #   # | { a = [x], b = "hi " ++ name } -> name
    #   input = [
    #     Token.new(:pipe, 1, 1),
    #     Token.new(:left_brace, 1, 3),
    #     Token.new(:identifier, "a", 1, 5),
    #     Token.new(:equals, 1, 7),
    #     Token.new(:left_bracket, 1, 9),
    #     Token.new(:identifier, "x", 1, 10),
    #     Token.new(:right_bracket, 1, 11),
    #     Token.new(:comma, 1, 12),
    #     Token.new(:identifier, "b", 1, 14),
    #     Token.new(:equals, 1, 16),
    #     Token.new(:text, "hi ", 1, 18),
    #     Token.new(:double_plus, 1, 23),
    #     Token.new(:identifier, "name", 1, 26),
    #     Token.new(:right_brace, 1, 30),
    #     Token.new(:right_arrow, 1, 32),
    #     Token.new(:identifier, "name", 1, 34),
    #     Token.new(:eof, 1, 38)
    #   ]

    #   expected =
    #     AST.pattern_match_expression([
    #       {
    #         AST.record_pattern([
    #           AST.record_pattern_field("a", AST.regular_list_pattern([AST.identifier("x")])),
    #           AST.record_pattern_field(
    #             "b",
    #             AST.text_pattern(AST.text("hi "), AST.identifier("name"))
    #           )
    #         ]),
    #         AST.identifier("name")
    #       }
    #     ])

    #   assert {:ok, ^expected} = Parser.parse(input)
    # end

    # @tag :skip
    # test "parses variant patterns" do
    #   # | #l n -> n * 2 | #r n -> n * 3
    #   input = [
    #     Token.new(:pipe, 1, 1),
    #     Token.new(:hashtag, 1, 3),
    #     Token.new(:identifier, "l", 1, 4),
    #     Token.new(:identifier, "n", 1, 6),
    #     Token.new(:right_arrow, 1, 8),
    #     Token.new(:identifier, "n", 1, 10),
    #     Token.new(:multiply, 1, 12),
    #     Token.new(:integer, 2, 1, 14),
    #     Token.new(:pipe, 1, 16),
    #     Token.new(:hashtag, 1, 18),
    #     Token.new(:identifier, "r", 1, 19),
    #     Token.new(:identifier, "n", 1, 21),
    #     Token.new(:right_arrow, 1, 23),
    #     Token.new(:identifier, "n", 1, 25),
    #     Token.new(:multiply, 1, 27),
    #     Token.new(:integer, 3, 1, 29),
    #     Token.new(:eof, 1, 30)
    #   ]

    #   expected =
    #     AST.pattern_match_expression([
    #       {
    #         AST.variant_pattern(AST.identifier("l"), [AST.identifier("n")]),
    #         AST.binary_op(AST.identifier("n"), :multiply, AST.integer(2))
    #       },
    #       {
    #         AST.variant_pattern(AST.identifier("r"), [AST.identifier("n")]),
    #         AST.binary_op(AST.identifier("n"), :multiply, AST.integer(3))
    #       }
    #     ])

    #   assert {:ok, ^expected} = Parser.parse(input)
    # end
  end
end
