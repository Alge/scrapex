defmodule Scrapex.Parser.InterpolatedTextTest do
  use ExUnit.Case, async: true

  alias Scrapex.{Parser, Token, AST}

  describe "interpolated text parsing" do
    test "parses simple interpolated text with variable" do
      # Input: "hello ` name ` world"
      input = [
        Token.new(:interpolated_text, "hello ` name ` world", 1, 1),
        Token.new(:eof, 1, 20)
      ]

      expected =
        AST.interpolated_text([
          "hello ",
          AST.identifier("name"),
          " world"
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses interpolated text with multiple expressions" do
      # Input: "count: ` x ` items, total: ` y `"
      input = [
        Token.new(:interpolated_text, "count: ` x ` items, total: ` y `", 1, 1),
        Token.new(:eof, 1, 34)
      ]

      expected =
        AST.interpolated_text([
          "count: ",
          AST.identifier("x"),
          " items, total: ",
          AST.identifier("y"),
          ""
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses interpolated text with arithmetic expression" do
      # Input: "result: ` x + 1 `"
      input = [
        Token.new(:interpolated_text, "result: ` x + 1 `", 1, 1),
        Token.new(:eof, 1, 18)
      ]

      expected =
        AST.interpolated_text([
          "result: ",
          AST.binary_op(AST.identifier("x"), :plus, AST.integer(1)),
          ""
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses interpolated text with function call" do
      # Input: "name: ` get_name user `"
      input = [
        Token.new(:interpolated_text, "name: ` get_name user `", 1, 1),
        Token.new(:eof, 1, 24)
      ]

      expected =
        AST.interpolated_text([
          "name: ",
          AST.function_app(AST.identifier("get_name"), AST.identifier("user")),
          ""
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses interpolated text with literal values" do
      # Input: "number: ` 42 `, text: ` \"hello\" `"
      input = [
        Token.new(:interpolated_text, "number: ` 42 `, text: ` \"hello\" `", 1, 1),
        Token.new(:eof, 1, 35)
      ]

      expected =
        AST.interpolated_text([
          "number: ",
          AST.integer(42),
          ", text: ",
          AST.text("hello"),
          ""
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses interpolated text with record access" do
      # Input: "user: ` person.name `"
      input = [
        Token.new(:interpolated_text, "user: ` person.name `", 1, 1),
        Token.new(:eof, 1, 22)
      ]

      expected =
        AST.interpolated_text([
          "user: ",
          AST.field_access(AST.identifier("person"), "name"),
          ""
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses interpolated text starting with expression" do
      # Input: "` greeting ` world"
      input = [
        Token.new(:interpolated_text, "` greeting ` world", 1, 1),
        Token.new(:eof, 1, 19)
      ]

      expected =
        AST.interpolated_text([
          "",
          AST.identifier("greeting"),
          " world"
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses interpolated text ending with expression" do
      # Input: "hello ` target `"
      input = [
        Token.new(:interpolated_text, "hello ` target `", 1, 1),
        Token.new(:eof, 1, 17)
      ]

      expected =
        AST.interpolated_text([
          "hello ",
          AST.identifier("target"),
          ""
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses interpolated text with only expression" do
      # Input: "` value `"
      input = [
        Token.new(:interpolated_text, "` value `", 1, 1),
        Token.new(:eof, 1, 10)
      ]

      expected =
        AST.interpolated_text([
          "",
          AST.identifier("value"),
          ""
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses interpolated text with empty expression" do
      # Input: "before ` ` after"
      input = [
        Token.new(:interpolated_text, "before ` ` after", 1, 1),
        Token.new(:eof, 1, 17)
      ]

      expected =
        AST.interpolated_text([
          "before ",
          # Empty expression becomes hole
          AST.hole(),
          " after"
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses interpolated text with complex nested expression" do
      # Input: "result: ` condition |> f `"
      input = [
        Token.new(:interpolated_text, "result: ` condition |> f `", 1, 1),
        Token.new(:eof, 1, 27)
      ]

      expected =
        AST.interpolated_text([
          "result: ",
          AST.binary_op(AST.identifier("condition"), :pipe_operator, AST.identifier("f")),
          ""
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "parses interpolated text in where clause" do
      # Input: result ; result = "hello ` name `"
      input = [
        Token.new(:identifier, "result", 1, 1),
        Token.new(:semicolon, 1, 8),
        Token.new(:identifier, "result", 1, 10),
        Token.new(:equals, 1, 17),
        Token.new(:interpolated_text, "hello ` name `", 1, 19),
        Token.new(:eof, 1, 34)
      ]

      expected =
        AST.where(
          AST.identifier("result"),
          AST.binding(
            "result",
            AST.interpolated_text([
              "hello ",
              AST.identifier("name"),
              ""
            ])
          )
        )

      assert {:ok, ^expected} = Parser.parse(input)
    end

    test "returns error for malformed interpolated text expression" do
      # Input: "hello ` 1 + `" (incomplete expression)
      input = [
        Token.new(:interpolated_text, "hello ` 1 + `", 1, 1),
        Token.new(:eof, 1, 15)
      ]

      result = Parser.parse(input)
      assert {:error, _reason} = result
    end

    test "returns error for unmatched backticks" do
      # Input: "hello ` world" (missing closing backtick)
      input = [
        Token.new(:interpolated_text, "hello ` world", 1, 1),
        Token.new(:eof, 1, 14)
      ]

      result = Parser.parse(input)
      assert {:error, _reason} = result
    end

    test "parses nested interpolated text" do
      # Input: "outer ` "inner ` x ` text" ` end"
      input = [
        Token.new(:interpolated_text, "outer ` \"inner ` x ` text\" ` end", 1, 1),
        Token.new(:eof, 1, 35)
      ]

      expected =
        AST.interpolated_text([
          "outer ",
          AST.interpolated_text([
            "inner ",
            AST.identifier("x"),
            " text"
          ]),
          " end"
        ])

      assert {:ok, ^expected} = Parser.parse(input)
    end
  end
end
