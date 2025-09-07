defmodule LexerTest do
  use ExUnit.Case

  alias Scrapex.Token
  alias Scrapex.Lexer

  test "empty input returns EOF" do
    expected = [Token.new(:eof, 1, 1)]
    assert Lexer.tokenize("") == expected
  end

  test "comment should extend to end of line" do
    expected = [Token.new(:eof, 1, 23)]
    assert Lexer.tokenize("  -- This is a comment") == expected
  end

  test "comment should not pick up new line" do
    expected = [Token.new(:eof, 2, 1)]
    assert Lexer.tokenize("-- This is a comment with newline after\n") == expected
  end

  test "Whitespace is ignored" do
    expected = [Token.new(:eof, 2, 6)]
    assert Lexer.tokenize("   \t \r\n    \t") == expected
  end

  test "dots are not part of identifiers" do
    expected = [
      Token.new(:identifier, "a", 1, 1),
      Token.new(:dot, 1, 2),
      Token.new(:identifier, "b", 1, 3),
      Token.new(:eof, 1, 4)
    ]

    assert Lexer.tokenize("a.b") == expected
  end

  test "Invalid character raises error" do
    assert_raise RuntimeError, "Unexpected character '@' at line 1, column 1", fn ->
      Lexer.tokenize("@")
    end
  end

  test "correct line numbers on tokens split across multiple lines" do
    expected = [
      Token.new(:plus, 1, 1),
      Token.new(:plus, 2, 1),
      Token.new(:eof, 2, 2)
    ]

    assert Lexer.tokenize("+\n+") == expected
  end

  test "tokenize combined values" do
    cases = [
      # Integers
      {"1", :integer, 1},
      {"123", :integer, 123},
      {"0", :integer, 0},

      # Floats
      {"1.0", :float, 1.0},
      {"0.0", :float, 0.0},
      {"12312313.12321312", :float, 12_312_313.12321312},

      # Text
      {"\"\"", :text, ""},
      {"\"a\"", :text, "a"},
      {"\"hello\"", :text, "hello"},
      {"\"This is text!\"", :text, "This is text!"},
      {"\"Text can contain wierd characters, !-0123+*/%&\"", :text,
       "Text can contain wierd characters, !-0123+*/%&"},
      {"\"1234\"", :text, "1234"},

      # Interpolated text:
      {"\"hello` \"🐸\" `frog\"", :interpolated_text, "hello` \"🐸\" `frog"},

      # Base64 tokens
      {"~~SGVsbG8gdGhlcmUh=", :base64, "SGVsbG8gdGhlcmUh="},
      # Short string with double '==' padding
      {"~~TQ==", :base64, "TQ=="},

      # String with no padding required
      {"~~TWFu", :base64, "TWFu"},

      # String containing the special '+' and '/' characters
      {"~~+/+", :base64, "+/+"},

      # A longer, complex string mixing cases, numbers, and symbols
      {"~~RWxpeGlyL1Bob2VuaXgrT1RQIHJvY2tzIQ==", :base64, "RWxpeGlyL1Bob2VuaXgrT1RQIHJvY2tzIQ=="},

      # Edge Case - An empty Base64 string (just the prefix)
      {"~~", :base64, ""},

      # String composed only of numbers
      {"~~MTIzNDU2", :base64, "MTIzNDU2"},

      # Another padding example to be sure
      {"~~bGlnaHQgd29yaw==", :base64, "bGlnaHQgd29yaw=="},

      ### HEX bytes
      {"~FF", :hexbyte, "FF"},
      {"~0F", :hexbyte, "0F"},
      {"~F0", :hexbyte, "F0"},
      {"~AB", :hexbyte, "AB"},
      {"~9C", :hexbyte, "9C"},

      # Same but lower case
      {"~ff", :hexbyte, "FF"},
      {"~0f", :hexbyte, "0F"},
      {"~f0", :hexbyte, "F0"},
      {"~ab", :hexbyte, "AB"},
      {"~9c", :hexbyte, "9C"},

      # Only zeroes
      {"~00", :hexbyte, "00"},
      {"~0", :hexbyte, "0"},

      ### Identifiers
      {"Hello", :identifier, "Hello"},
      {"hello", :identifier, "hello"},
      {"x-y", :identifier, "x-y"},
      {"a", :identifier, "a"},
      {"_asd", :identifier, "_asd"},
      {"3d", :identifier, "3d"},
      {"3_", :identifier, "3_"},
      {"3-", :identifier, "3-"},
      {"3d__", :identifier, "3d__"},
      {"3__d--", :identifier, "3__d--"},
      {"abc-123", :identifier, "abc-123"},
      {"123-abc", :identifier, "123-abc"}
    ]

    for {input, expected_type, expected_value} <- cases do
      expected = [
        Token.new(expected_type, expected_value, 1, 1),
        Token.new(:eof, 1, String.length(input) + 1)
      ]

      assert Lexer.tokenize(input) == expected
    end
  end

  test "tokenizes single character operators" do
    cases = [
      {"+", :plus},
      {"(", :left_paren},
      {")", :right_paren},
      {"-", :minus},
      {"*", :multiply},
      {"|", :pipe},
      {";", :semicolon},
      {":", :colon},
      {"=", :equals},
      {"#", :hashtag},
      {"<", :less_than},
      {">", :greater_than},
      {"{", :left_brace},
      {"}", :right_brace},
      {"[", :left_bracket},
      {"]", :right_bracket},
      {".", :dot},
      {",", :comma},
      {"_", :underscore},
      {"!", :exclamation_mark},
      {"/", :slash}
    ]

    for {input, expected_type} <- cases do
      expected = [
        Token.new(expected_type, 1, 1),
        Token.new(:eof, 1, 2)
      ]

      assert Lexer.tokenize(input) == expected
    end
  end

  test "tokenizes multi character operators" do
    cases = [
      {"++", :double_plus},
      {"+<", :append},
      {"->", :right_arrow},
      {"::", :double_colon},
      {"..", :double_dot},
      {">>", :pipe_forward}
    ]

    for {input, expected_type} <- cases do
      expected = [
        Token.new(expected_type, 1, 1),
        Token.new(:eof, 1, String.length(input) + 1)
      ]

      assert Lexer.tokenize(input) == expected
    end
  end
end
