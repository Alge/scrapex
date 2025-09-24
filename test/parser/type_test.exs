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

    expected = Expression.type_declaration("bool", AST.type_union([AST.variant("true")]))

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses type declaration with multiple variants" do
    # Input: "scoop : #vanilla #chocolate #strawberry"
    input = [
      Token.new(:identifier, "scoop", 1, 1),
      Token.new(:colon, 1, 7),
      Token.new(:hashtag, 1, 9),
      Token.new(:identifier, "vanilla", 1, 10),
      Token.new(:hashtag, 1, 18),
      Token.new(:identifier, "chocolate", 1, 19),
      Token.new(:hashtag, 1, 29),
      Token.new(:identifier, "strawberry", 1, 30),
      Token.new(:eof, 1, 40)
    ]

    expected =
      Expression.type_declaration(
        "scoop",
        AST.type_union([
          AST.variant("vanilla"),
          AST.variant("chocolate"),
          AST.variant("strawberry")
        ])
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses type declaration within where-clause" do
    # Input: "x ; x : #a #b"
    input = [
      Token.new(:identifier, "x", 1, 1),
      Token.new(:semicolon, 1, 3),
      Token.new(:identifier, "x", 1, 5),
      Token.new(:colon, 1, 7),
      Token.new(:hashtag, 1, 9),
      Token.new(:identifier, "a", 1, 10),
      Token.new(:hashtag, 1, 12),
      Token.new(:identifier, "b", 1, 13),
      Token.new(:eof, 1, 14)
    ]

    expected =
      Expression.where(
        AST.identifier("x"),
        Expression.type_declaration(
          "x",
          AST.type_union([AST.variant("a"), AST.variant("b")])
        )
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "distinguishes type declaration from regular colon usage" do
    # Input: "x : int" (not a type declaration since "int" is not a variant)
    input = [
      Token.new(:identifier, "x", 1, 1),
      Token.new(:colon, 1, 3),
      Token.new(:identifier, "int", 1, 5),
      Token.new(:eof, 1, 8)
    ]

    # This should parse as a type_annotation, which is more specific
    # and correct than a generic binary_op.
    expected =
      AST.type_annotation(
        AST.identifier("x"),
        AST.identifier("int")
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses type declaration followed by other expression" do
    # Input: "t : #a #b + 1"
    input = [
      Token.new(:identifier, "t", 1, 1),
      Token.new(:colon, 1, 3),
      Token.new(:hashtag, 1, 5),
      Token.new(:identifier, "a", 1, 6),
      Token.new(:hashtag, 1, 8),
      Token.new(:identifier, "b", 1, 9),
      Token.new(:plus, 1, 11),
      Token.new(:integer, 1, 1, 13),
      Token.new(:eof, 1, 14)
    ]

    expected =
      Expression.binary_op(
        Expression.type_declaration(
          "t",
          AST.type_union([AST.variant("a"), AST.variant("b")])
        ),
        :plus,
        AST.integer(1)
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end

  test "parses type annotation with non-identifier left side (will fail at evaluation)" do
    # Input: "123 : #a" (parseable but semantically invalid)
    input = [
      Token.new(:integer, 123, 1, 1),
      Token.new(:colon, 1, 5),
      Token.new(:hashtag, 1, 7),
      Token.new(:identifier, "a", 1, 8),
      Token.new(:eof, 1, 9)
    ]

    # Parser succeeds: creates type annotation with atomic tag
    expected =
      AST.type_annotation(
        AST.integer(123),
        AST.variant("a")
      )

    assert {:ok, result} = Parser.parse(input)
    assert result == expected
  end
end
