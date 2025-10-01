defmodule Scrapex.Parser.TypeTest do
  use ExUnit.Case
  alias Scrapex.{Parser, Token}
  alias Scrapex.AST.{Expression}
  alias Scrapex.AST

  test "parses simple type declaration with single variant" do
    # Input: "bool : #true"
    input = [
      Token.new(:identifier, "bool", 1, 1),
      Token.new(:colon, 1, 6),
      Token.new(:hashtag, 1, 8),
      Token.new(:identifier, "true", 1, 9),
      Token.new(:eof, 1, 13)
    ]

    expected = Expression.type_declaration("bool", AST.type_union([AST.variant_def("true")]))

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses type declaration with nullary variants (no payload)" do
    # Input: "bool : #true | #false"
    # Variants have no payload - they're just tags
    input = [
      Token.new(:identifier, "bool", 1, 1),
      Token.new(:colon, 1, 6),
      Token.new(:hashtag, 1, 8),
      Token.new(:identifier, "true", 1, 9),
      Token.new(:pipe, 1, 14),
      Token.new(:hashtag, 1, 16),
      Token.new(:identifier, "false", 1, 17),
      Token.new(:eof, 1, 22)
    ]

    expected =
      Expression.type_declaration(
        "bool",
        AST.type_union([
          AST.variant_def("true", AST.hole()),
          AST.variant_def("false", AST.hole())
        ])
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses type declaration with multiple variants using pipes" do
    # Input: "scoop : #vanilla | #chocolate | #strawberry"
    input = [
      Token.new(:identifier, "scoop", 1, 1),
      Token.new(:colon, 1, 7),
      Token.new(:hashtag, 1, 9),
      Token.new(:identifier, "vanilla", 1, 10),
      Token.new(:pipe, 1, 18),
      Token.new(:hashtag, 1, 20),
      Token.new(:identifier, "chocolate", 1, 21),
      Token.new(:pipe, 1, 31),
      Token.new(:hashtag, 1, 33),
      Token.new(:identifier, "strawberry", 1, 34),
      Token.new(:eof, 1, 44)
    ]

    expected =
      Expression.type_declaration(
        "scoop",
        AST.type_union([
          AST.variant_def("vanilla"),
          AST.variant_def("chocolate"),
          AST.variant_def("strawberry")
        ])
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses type declaration with variant carrying payload" do
    # Input: "c : #radius int"
    input = [
      Token.new(:identifier, "c", 1, 1),
      Token.new(:colon, 1, 3),
      Token.new(:hashtag, 1, 5),
      Token.new(:identifier, "radius", 1, 6),
      Token.new(:identifier, "int", 1, 13),
      Token.new(:eof, 1, 16)
    ]

    expected =
      Expression.type_declaration(
        "c",
        AST.type_union([
          AST.variant_def("radius", AST.identifier("int"))
        ])
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses type declaration within where-clause" do
    # Input: "x ; x : #a | #b"
    input = [
      Token.new(:identifier, "x", 1, 1),
      Token.new(:semicolon, 1, 3),
      Token.new(:identifier, "x", 1, 5),
      Token.new(:colon, 1, 7),
      Token.new(:hashtag, 1, 9),
      Token.new(:identifier, "a", 1, 10),
      Token.new(:pipe, 1, 12),
      Token.new(:hashtag, 1, 14),
      Token.new(:identifier, "b", 1, 15),
      Token.new(:eof, 1, 16)
    ]

    expected =
      Expression.where(
        AST.identifier("x"),
        Expression.type_declaration(
          "x",
          AST.type_union([AST.variant_def("a"), AST.variant_def("b")])
        )
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses type declaration followed by other expression" do
    # Input: "t : #a | #b + 1"
    input = [
      Token.new(:identifier, "t", 1, 1),
      Token.new(:colon, 1, 3),
      Token.new(:hashtag, 1, 5),
      Token.new(:identifier, "a", 1, 6),
      Token.new(:pipe, 1, 8),
      Token.new(:hashtag, 1, 10),
      Token.new(:identifier, "b", 1, 11),
      Token.new(:plus, 1, 13),
      Token.new(:integer, 1, 1, 15),
      Token.new(:eof, 1, 16)
    ]

    expected =
      Expression.binary_op(
        Expression.type_declaration(
          "t",
          AST.type_union([AST.variant_def("a"), AST.variant_def("b")])
        ),
        :plus,
        AST.integer(1)
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses type declaration with variants separated by pipes" do
    # Input: "payment : #card | #cash"
    input = [
      Token.new(:identifier, "payment", 1, 1),
      Token.new(:colon, 1, 9),
      Token.new(:hashtag, 1, 11),
      Token.new(:identifier, "card", 1, 12),
      Token.new(:pipe, 1, 17),
      Token.new(:hashtag, 1, 19),
      Token.new(:identifier, "cash", 1, 20),
      Token.new(:eof, 1, 24)
    ]

    expected =
      AST.type_declaration(
        "payment",
        AST.type_union([
          AST.variant_def("card"),
          AST.variant_def("cash")
        ])
      )

    assert {:ok, ^expected} = Parser.parse(input)
  end
end
