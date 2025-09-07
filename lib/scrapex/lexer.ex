defmodule Scrapex.Lexer do
  alias Scrapex.Token
  require Logger

  defp token_patterns do
    [
      # # Comments (should be early to avoid conflicts)
      {:comment, ~r/^--.*/},

      # Identifiers needs to be very high up in prio order due to wierd rules
      # Identifier Rules:
      # Allowed: letters (a-z, A-Z), digits (0-9), underscore (_), dash (-)
      # Cannot start with: dash (-abc)
      # Cannot be only: single underscore (_) or digits only (123)
      # Cannot contain: dots or other special characters
      # Valid: Hello, 3d, _var, abc-123, my_var, 3_
      # Invalid: _, 123, 1.0, -abc, my.var
      {:identifier, ~r/^(?!_$)(?![0-9]+$)(?![0-9]+\.[0-9]+$)(?!-)[a-zA-Z0-9_-]+/},

      # # Multi-character operators (longer first)
      {:double_plus, ~r/^\+\+/},
      {:append, ~r/^\+</},
      {:right_arrow, ~r/^->/},
      {:double_colon, ~r/^::/},
      {:double_dot, ~r/^\.\./},
      {:pipe_forward, ~r/^>>/},

      # # Literals (longer/more specific first)
      {:interpolated_text, ~r/^"(?:[^`]*`[^`]*`)+[^`]*"/},
      {:text, ~r/^"[^"]*"/},
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
    case match_next_token(input) do
      {:ok, type, value, consumed_length} ->
        process_token(type, value, input, tokens, line, col, consumed_length)

      :no_match ->
        char = String.first(input)
        Logger.error("Unexpected character '#{char}' at line #{line}, column #{col}")
        raise "Unexpected character '#{char}' at line #{line}, column #{col}"
    end
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

  defp process_token(type, value, input, tokens, line, col, length)
      when type in [:text, :interpolated_text] do
    token = Token.new(type, String.slice(value, 1..-2//1), line, col)
    rest = String.slice(input, length..-1//1)
    scan_tokens(rest, [token | tokens], line, col + length)
  end

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
