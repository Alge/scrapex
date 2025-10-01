defmodule Scrapex.Parser.VariantConstructionTest do
  use ExUnit.Case, async: true

  alias Scrapex.{Parser, Token, AST}

  describe "direct variant construction (no type specified)" do
    test "parses a nullary variant" do
      # Input: "#true"
      # This is just a tagged value - NO type associated with it
      # It could be used with any type that has a #true variant
      input = [
        Token.new(:hashtag, 1, 1),
        Token.new(:identifier, "true", 1, 2),
        Token.new(:eof, 1, 6)
      ]

      expected = AST.variant("true")

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a variant with a single payload" do
      # Input: "#some 42"
      input = [
        Token.new(:hashtag, 1, 1),
        Token.new(:identifier, "some", 1, 2),
        Token.new(:integer, 42, 1, 7),
        Token.new(:eof, 1, 9)
      ]

      expected = AST.variant("some", AST.integer(42))

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a variant with another variant as payload" do
      # Input: "#ok #chips"
      input = [
        Token.new(:hashtag, 1, 1),
        Token.new(:identifier, "ok", 1, 2),
        Token.new(:hashtag, 1, 5),
        Token.new(:identifier, "chips", 1, 6),
        Token.new(:eof, 1, 11)
      ]

      expected = AST.variant("ok", AST.variant("chips"))

      assert {:ok, result} = Parser.parse(input)
      assert result == expected
    end

    test "parses a variant with a parenthesized expression payload" do
      # Input: "#error (1 + 2)"
      input = [
        Token.new(:hashtag, 1, 1),
        Token.new(:identifier, "error", 1, 2),
        Token.new(:left_paren, 1, 8),
        Token.new(:integer, 1, 1, 9),
        Token.new(:plus, 1, 11),
        Token.new(:integer, 2, 1, 13),
        Token.new(:right_paren, 1, 14),
        Token.new(:eof, 1, 15)
      ]

      expected = AST.variant("error", AST.binary_op(AST.integer(1), :plus, AST.integer(2)))

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses a variant in where-clause binding" do
      # Input: "x ; x = #ok"
      input = [
        Token.new(:identifier, "x", 1, 1),
        Token.new(:semicolon, 1, 3),
        Token.new(:identifier, "x", 1, 5),
        Token.new(:equals, 1, 7),
        Token.new(:hashtag, 1, 9),
        Token.new(:identifier, "ok", 1, 10),
        Token.new(:eof, 1, 12)
      ]

      expected =
        AST.where(
          AST.identifier("x"),
          AST.binding("x", AST.variant("ok"))
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end

  describe "type construction with :: (explicit type + constructor invocation)" do
    test "parses simple type construction with single argument" do
      # Input: "c::radius 4"
      # Type definition: c : #radius int
      # Construction: c::radius 4 (no # in construction)
      input = [
        Token.new(:identifier, "c", 1, 1),
        Token.new(:double_colon, 1, 2),
        Token.new(:identifier, "radius", 1, 4),
        Token.new(:integer, 4, 1, 11),
        Token.new(:eof, 1, 12)
      ]

      expected =
        AST.type_construction(
          "c",
          "radius",
          [AST.integer(4)]
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses type construction with multiple arguments" do
      # Input: "point::3d 1.0 \"A\" ~2B"
      # Type definition: point : x => y => z => #3d { x : x, y : y, z : z }
      # Construction uses identifier "3d" WITHOUT #
      input = [
        Token.new(:identifier, "point", 1, 1),
        Token.new(:double_colon, 1, 6),
        Token.new(:identifier, "3d", 1, 8),
        Token.new(:float, 1.0, 1, 11),
        Token.new(:text, "A", 1, 15),
        Token.new(:hexbyte, "2B", 1, 19),
        Token.new(:eof, 1, 22)
      ]

      expected =
        AST.type_construction(
          "point",
          "3d",
          [AST.float(1.0), AST.text("A"), AST.hexbyte("2B")]
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses type construction with nullary variant" do
      # Input: "bool::true"
      # Type definition: bool : #true | #false
      # Construction: bool::true (no #)
      input = [
        Token.new(:identifier, "bool", 1, 1),
        Token.new(:double_colon, 1, 5),
        Token.new(:identifier, "true", 1, 7),
        Token.new(:eof, 1, 11)
      ]

      expected =
        AST.type_construction(
          "bool",
          "true",
          []
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses type construction in where clause" do
      # Input: "x ; x = payment::exact-change 5"
      # Type definition: payment : #exact-change int | #credit-card
      input = [
        Token.new(:identifier, "x", 1, 1),
        Token.new(:semicolon, 1, 3),
        Token.new(:identifier, "x", 1, 5),
        Token.new(:equals, 1, 7),
        Token.new(:identifier, "payment", 1, 9),
        Token.new(:double_colon, 1, 16),
        Token.new(:identifier, "exact-change", 1, 18),
        Token.new(:integer, 5, 1, 31),
        Token.new(:eof, 1, 32)
      ]

      expected =
        AST.where(
          AST.identifier("x"),
          AST.binding(
            "x",
            AST.type_construction(
              "payment",
              "exact-change",
              [AST.integer(5)]
            )
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses scoop example from guide" do
      # Input: "scoop::chocolate"
      # Type definition: scoop : #vanilla #chocolate #strawberry
      input = [
        Token.new(:identifier, "scoop", 1, 1),
        Token.new(:double_colon, 1, 6),
        Token.new(:identifier, "chocolate", 1, 8),
        Token.new(:eof, 1, 17)
      ]

      expected =
        AST.type_construction(
          "scoop",
          "chocolate",
          []
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "vending machine full example" do
      # Input: "process-transaction my-payment ; my-payment = payment::exact-change 5"
      input = [
        Token.new(:identifier, "process-transaction", 1, 1),
        Token.new(:identifier, "my-payment", 1, 21),
        Token.new(:semicolon, 1, 32),
        Token.new(:identifier, "my-payment", 1, 34),
        Token.new(:equals, 1, 45),
        Token.new(:identifier, "payment", 1, 47),
        Token.new(:double_colon, 1, 54),
        Token.new(:identifier, "exact-change", 1, 56),
        Token.new(:integer, 5, 1, 69),
        Token.new(:eof, 1, 70)
      ]

      expected =
        AST.where(
          AST.function_app(
            AST.identifier("process-transaction"),
            AST.identifier("my-payment")
          ),
          AST.binding(
            "my-payment",
            AST.type_construction(
              "payment",
              "exact-change",
              [AST.integer(5)]
            )
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "rejects hashtag after double colon" do
      # Input: "bool::#true" - should be a parse error
      input = [
        Token.new(:identifier, "bool", 1, 1),
        Token.new(:double_colon, 1, 5),
        Token.new(:hashtag, 1, 7),
        Token.new(:identifier, "true", 1, 8),
        Token.new(:eof, 1, 12)
      ]

      assert {:error, _reason} = Parser.parse(input)
    end
  end
end
