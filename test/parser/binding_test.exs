# test/parser/binding_test.exs
defmodule Scrapex.Parser.BindingTest do
  use ExUnit.Case, async: true

  alias Scrapex.{Parser, Token, AST}

  describe "assignment expressions (should become parse errors)" do
    @tag :skip
    test "standalone assignment should be parse error" do
      # Input: "x = 42" (not in where clause)
      input = [
        Token.new(:identifier, "x", 1, 1),
        Token.new(:equals, 1, 3),
        Token.new(:integer, 42, 1, 5),
        Token.new(:eof, 1, 7)
      ]

      # This should become a parse error after refactoring
      assert {:error, _reason} = Parser.parse(input)
    end

    @tag :skip
    test "assignment in arithmetic expression should be parse error" do
      # Input: "1 + (x = 42)" - assignment not allowed in expression context
      input = [
        Token.new(:integer, 1, 1, 1),
        Token.new(:plus, 1, 3),
        Token.new(:left_paren, 1, 5),
        Token.new(:identifier, "x", 1, 6),
        Token.new(:equals, 1, 8),
        Token.new(:integer, 42, 1, 10),
        Token.new(:right_paren, 1, 12),
        Token.new(:eof, 1, 13)
      ]

      assert {:error, _reason} = Parser.parse(input)
    end
  end

  describe "where clause bindings (new dedicated syntax)" do
    test "parses simple variable binding" do
      # Input: "x ; x = 42"
      input = [
        Token.new(:identifier, "x", 1, 1),
        Token.new(:semicolon, 1, 3),
        Token.new(:identifier, "x", 1, 5),
        Token.new(:equals, 1, 7),
        Token.new(:integer, 42, 1, 9),
        Token.new(:eof, 1, 11)
      ]

      # After refactor: binding should be dedicated AST node, not binary_op
      expected =
        AST.where(
          AST.identifier("x"),
          # New binding node, not binary_op
          {:binding, "x", AST.integer(42)}
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses binding with complex expression" do
      # Input: "result ; result = x + y"
      input = [
        Token.new(:identifier, "result", 1, 1),
        Token.new(:semicolon, 1, 8),
        Token.new(:identifier, "result", 1, 10),
        Token.new(:equals, 1, 17),
        Token.new(:identifier, "x", 1, 19),
        Token.new(:plus, 1, 21),
        Token.new(:identifier, "y", 1, 23),
        Token.new(:eof, 1, 24)
      ]

      expected =
        AST.where(
          AST.identifier("result"),
          {:binding, "result", AST.binary_op(AST.identifier("x"), :plus, AST.identifier("y"))}
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses chained bindings" do
      # Input: "result ; x = 10 ; y = 20"
      input = [
        Token.new(:identifier, "result", 1, 1),
        Token.new(:semicolon, 1, 8),
        Token.new(:identifier, "x", 1, 10),
        Token.new(:equals, 1, 12),
        Token.new(:integer, 10, 1, 14),
        Token.new(:semicolon, 1, 16),
        Token.new(:identifier, "y", 1, 18),
        Token.new(:equals, 1, 20),
        Token.new(:integer, 20, 1, 22),
        Token.new(:eof, 1, 24)
      ]

      expected =
        AST.where(
          AST.identifier("result"),
          AST.where(
            {:binding, "x", AST.integer(10)},
            {:binding, "y", AST.integer(20)}
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end

  describe "typed bindings (future feature)" do
    @tag :skip
    test "parses typed variable binding" do
      # Input: "x ; x : int = 42"
      input = [
        Token.new(:identifier, "x", 1, 1),
        Token.new(:semicolon, 1, 3),
        Token.new(:identifier, "x", 1, 5),
        Token.new(:colon, 1, 7),
        Token.new(:identifier, "int", 1, 9),
        Token.new(:equals, 1, 13),
        Token.new(:integer, 42, 1, 15),
        Token.new(:eof, 1, 17)
      ]

      expected =
        AST.where(
          AST.identifier("x"),
          {:typed_binding, "x", AST.identifier("int"), AST.integer(42)}
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    @tag :skip
    test "parses type declaration binding" do
      # Input: "t ; t : #variant1 #variant2"
      input = [
        Token.new(:identifier, "t", 1, 1),
        Token.new(:semicolon, 1, 3),
        Token.new(:identifier, "t", 1, 5),
        Token.new(:colon, 1, 7),
        Token.new(:hashtag, 1, 9),
        Token.new(:identifier, "variant1", 1, 10),
        Token.new(:hashtag, 1, 19),
        Token.new(:identifier, "variant2", 1, 20),
        Token.new(:eof, 1, 28)
      ]

      expected =
        AST.where(
          AST.identifier("t"),
          {:type_binding, "t",
           AST.type_union([
             AST.variant("variant1"),
             AST.variant("variant2")
           ])}
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end

  describe "chaining different binding types" do
    test "parses type declaration followed by assignment" do
      # Input: "result ; person : #cowboy ; x = 42"
      input = [
        Token.new(:identifier, "result", 1, 1),
        Token.new(:semicolon, 1, 8),
        Token.new(:identifier, "person", 1, 10),
        Token.new(:colon, 1, 17),
        Token.new(:hashtag, 1, 19),
        Token.new(:identifier, "cowboy", 1, 20),
        Token.new(:semicolon, 1, 27),
        Token.new(:identifier, "x", 1, 29),
        Token.new(:equals, 1, 31),
        Token.new(:integer, 42, 1, 33),
        Token.new(:eof, 1, 35)
      ]

      expected =
        AST.where(
          AST.identifier("result"),
          AST.where(
            AST.type_declaration("person", [AST.variant("cowboy")]),
            AST.binding("x", AST.integer(42))
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    @tag :skip
    test "parses type annotation followed by assignment" do
      # Input: "result ; x : int ; y = 42"
      input = [
        Token.new(:identifier, "result", 1, 1),
        Token.new(:semicolon, 1, 8),
        Token.new(:identifier, "x", 1, 10),
        Token.new(:colon, 1, 12),
        Token.new(:identifier, "int", 1, 14),
        Token.new(:semicolon, 1, 18),
        Token.new(:identifier, "y", 1, 20),
        Token.new(:equals, 1, 22),
        Token.new(:integer, 42, 1, 24),
        Token.new(:eof, 1, 26)
      ]

      expected =
        AST.where(
          AST.identifier("result"),
          AST.where(
            AST.type_annotation(AST.identifier("x"), AST.identifier("int")),
            AST.binding("y", AST.integer(42))
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end
end
