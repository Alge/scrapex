defmodule Scrapex.Lexer do
  alias Scrapex.Token
  require Logger

  defp token_patterns do
    [
      # # Comments (should be early to avoid conflicts)
      {:comment, ~r/^--.*/},

      # Identifiers needs to be very high up in prio order due to wierd rules
      # Identifier Rules:
      # Allowed: letters (a-z, A-Z), digits (0-9), underscore (_), dash (-), forward slash (/)
      # Cannot start with: dash (-abc) or slash (/abc)
      # Cannot be only: single underscore (_) or digits only (123)
      # Cannot end with: slash (abc/)
      # Cannot contain: double slashes (abc//def)
      # Valid: Hello, 3d, _var, abc-123, my_var, 3_, connie2036/echo, bytes/to-utf8-text
      # Invalid: _, 123, 1.0, -abc, *var, abc/, /abc, abc//def
      {:identifier,
       ~r/^(?!(?:_|[0-9]+|-)(?![a-zA-Z0-9_-]))[a-zA-Z0-9_][a-zA-Z0-9_-]*(?:\/[a-zA-Z0-9_][a-zA-Z0-9_-]*)*(?<!\/)/},

      # # Multi-character operators (longer first)
      {:double_plus, ~r/^\+\+/},
      {:append, ~r/^\+</},
      {:cons, ~r/^\>\+/},
      {:right_arrow, ~r/^->/},
      {:double_arrow, ~r/^=>/},
      {:double_colon, ~r/^::/},
      {:double_dot, ~r/^\.\./},
      {:pipe_forward, ~r/^>>/},
      {:pipe_operator, ~r/^\|\>/},
      {:rock, ~r/^\$\$/},
      {:double_equals, ~r/^==/},
      {:not_equals, ~r/^!=/},

      # # Literals (longer/more specific first)
      # Note: Both :text and :interpolated_text now handled by custom parser
      {:base64, ~r/^~~[A-Za-z0-9+\/]*={0,2}/},
      {:hexbyte, ~r/^~[0-9a-fA-F]{1,2}/},
      {:float, ~r/^\d+\.\d+/},
      {:integer, ~r/^\d+/},

      # # Single character operators
      {:pipe, ~r/^\|/},
      {:hashtag, ~r/^#/},
      {:semicolon, ~r/^;/},
      {:colon, ~r/^:/},
      {:equals, ~r/^=/},
      {:plus, ~r/^\+/},
      {:minus, ~r/^-/},
      {:slash, ~r/^\//},
      {:multiply, ~r/^\*/},
      {:greater_than, ~r/^>/},
      {:less_than, ~r/^</},
      {:left_paren, ~r/^\(/},
      {:right_paren, ~r/^\)/},
      {:left_brace, ~r/^\{/},
      {:right_brace, ~r/^\}/},
      {:left_bracket, ~r/^\[/},
      {:right_bracket, ~r/^\]/},
      {:dot, ~r/^\./},
      {:comma, ~r/^,/},
      {:underscore, ~r/^_/},
      {:exclamation_mark, ~r/^!/},
      {:at, ~r/^@/},

      # Whitespace (handle last). These are not emitted but the lexer, but we
      # need to keep track of them to track lines/columns correctly!
      {:newline, ~r/^\r?\n/},
      {:whitespace, ~r/^[^\S\r\n]+/}
    ]
  end

  @spec tokenize(String.t()) :: list(Token.t())
  def tokenize(input) do
    scan_tokens(input, [], 1, 1)
    |> Enum.reverse()
  end

  # End of input
  defp scan_tokens("", tokens, line, col) do
    [Token.new(:eof, line, col) | tokens]
  end

  defp scan_tokens(input, tokens, line, col) do
    # Check for any quoted string first (both text and interpolated_text)
    case try_parse_quoted_string(input) do
      {:ok, type, content, consumed_length} ->
        token = Token.new(type, content, line, col)
        rest = String.slice(input, consumed_length..-1//1)
        scan_tokens(rest, [token | tokens], line, col + consumed_length)

      :no_match ->
        # Fall back to regular pattern matching
        case match_next_token(input) do
          {:ok, type, value, consumed_length} ->
            process_token(type, value, input, tokens, line, col, consumed_length)

          :no_match ->
            char = String.first(input)
            Logger.error("Unexpected character '#{char}' at line #{line}, column #{col}")
            raise "Unexpected character '#{char}' at line #{line}, column #{col}"
        end
    end
  end

  # Try to parse any quoted string (both text and interpolated_text)
  defp try_parse_quoted_string(<<"\"", _rest::binary>> = input) do
    case parse_quoted_string_with_interpolation(input, 0) do
      {:ok, content, length} ->
        # Remove surrounding quotes to get inner content
        inner_content = String.slice(content, 1..-2//1)

        # Determine type based on whether it contains interpolation (backticks)
        type = if String.contains?(content, "`"), do: :interpolated_text, else: :text

        {:ok, type, inner_content, length}

      :no_match ->
        :no_match
    end
  end

  defp try_parse_quoted_string(_input), do: :no_match

  # Parse a quoted string that may contain nested interpolation
  defp parse_quoted_string_with_interpolation(<<"\"", rest::binary>>, start_pos) do
    # Start parsing after the opening quote
    parse_quoted_string_helper(rest, 1, false, "\"")
  end

  defp parse_quoted_string_with_interpolation(_, _), do: :no_match

  # Helper function that does the actual parsing
  # Base case: reached end of input without closing quote
  defp parse_quoted_string_helper("", _pos, _in_backtick, _acc) do
    :no_match
  end

  # Found closing quote and not inside backticks
  defp parse_quoted_string_helper(<<"\"", rest::binary>>, pos, false, acc) do
    final_content = acc <> "\""
    {:ok, final_content, pos + 1}
  end

  # Found opening backtick (start interpolation)
  defp parse_quoted_string_helper(<<"`", rest::binary>>, pos, false, acc) do
    parse_quoted_string_helper(rest, pos + 1, true, acc <> "`")
  end

  # Found closing backtick (end interpolation)
  defp parse_quoted_string_helper(<<"`", rest::binary>>, pos, true, acc) do
    parse_quoted_string_helper(rest, pos + 1, false, acc <> "`")
  end

  # Found quote inside backticks - start nested parsing
  defp parse_quoted_string_helper(<<"\"", _rest::binary>> = input, pos, true, acc) do
    # Recursively parse the nested quoted string
    case parse_quoted_string_with_interpolation(input, pos) do
      {:ok, nested_content, nested_length} ->
        # Continue parsing after the nested string
        remaining_input = String.slice(input, nested_length..-1//1)
        new_acc = acc <> nested_content
        parse_quoted_string_helper(remaining_input, pos + nested_length, true, new_acc)

      :no_match ->
        :no_match
    end
  end

  # Found escaped character
  defp parse_quoted_string_helper(<<"\\", char, rest::binary>>, pos, in_backtick, acc) do
    parse_quoted_string_helper(rest, pos + 2, in_backtick, acc <> "\\" <> <<char>>)
  end

  # Regular character
  defp parse_quoted_string_helper(<<char, rest::binary>>, pos, in_backtick, acc) do
    parse_quoted_string_helper(rest, pos + 1, in_backtick, acc <> <<char>>)
  end

  defp match_next_token(input) do
    # Try each pattern until one matches - now using the function instead of module attribute
    Enum.find_value(token_patterns(), :no_match, fn {type, pattern} ->
      case Regex.run(pattern, input) do
        [match] -> {:ok, type, match, String.length(match)}
        nil -> nil
      end
    end)
  end

  defp process_token(type, _value, input, tokens, line, col, length)
       when type in [:whitespace, :comment] do
    # Don't add this to the token list, but add the length to the column for tracking
    rest = String.slice(input, length..-1//1)
    scan_tokens(rest, tokens, line, col + length)
  end

  defp process_token(:newline, _value, input, tokens, line, _col, length) do
    # Don't add this to the token list, but increment the line count and reset the column count
    rest = String.slice(input, length..-1//1)
    scan_tokens(rest, tokens, line + 1, 1)
  end

  defp process_token(:integer, value, input, tokens, line, col, length) do
    token = Token.new(:integer, String.to_integer(value), line, col)
    rest = String.slice(input, length..-1//1)
    scan_tokens(rest, [token | tokens], line, col + length)
  end

  defp process_token(:float, value, input, tokens, line, col, length) do
    token = Token.new(:float, String.to_float(value), line, col)
    rest = String.slice(input, length..-1//1)
    scan_tokens(rest, [token | tokens], line, col + length)
  end

  # Note: :text and :interpolated_text are now handled by custom parser,
  # not through this process_token function

  defp process_token(:hexbyte, value, input, tokens, line, col, length) do
    # Trim the leading "~" from the value.
    <<"~", content::binary>> = value
    token = Token.new(:hexbyte, String.upcase(content), line, col)
    rest = String.slice(input, length..-1//1)
    scan_tokens(rest, [token | tokens], line, col + length)
  end

  defp process_token(:base64, value, input, tokens, line, col, length) do
    # Trim the leading "~~" from the value.
    <<"~~", content::binary>> = value

    token = Token.new(:base64, content, line, col)
    rest = String.slice(input, length..-1//1)
    scan_tokens(rest, [token | tokens], line, col + length)
  end

  defp process_token(:identifier, value, input, tokens, line, col, length) do
    token = Token.new(:identifier, value, line, col)
    rest = String.slice(input, length..-1//1)
    scan_tokens(rest, [token | tokens], line, col + length)
  end

  defp process_token(type, _value, input, tokens, line, col, length) do
    token = Token.new(type, line, col)
    rest = String.slice(input, length..-1//1)
    scan_tokens(rest, [token | tokens], line, col + length)
  end
end
