defmodule Scrapex.Parser do
  alias Scrapex.{Token, AST}

  def parse(token_list) when is_list(token_list) do
    # First, handle the edge case of empty or effectively empty input.
    if token_list == [] or hd(token_list).type == :eof do
      {:error, "Empty input"}
    else
      # The main logic: parse one full expression, starting with precedence 0.
      case parse_expression(token_list, 0) do
        # The success case: we got an expression and the ONLY thing left is EOF.
        {:ok, expression_ast, [%Token{type: :eof} | _]} ->
          # We return the expression AST directly, no program wrapper.
          {:ok, expression_ast}

        # Error Case 1: We parsed an expression, but there's junk left over.
        {:ok, _expression_ast, [other_token | _]} ->
          {:error, "Unexpected token after expression: #{Token.to_string(other_token)}"}

        # Error Case 2: The expression parser itself failed.
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def parse_expression(token_list, precedence_context) do
    case parse_prefix_expression(token_list) do
      {:ok, left_ast, rest} ->
        # Check for the optional infix?
        # This would mean that we check for a operator here
        # so something like case next where next in operators?
        parse_infix_expression(rest, left_ast, precedence_context)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_infix_expression(token_list, left_ast, precedence_context) do
    if token_list == [] or hd(token_list).type == :eof do
      # The expression is just the prefix part.
      {:ok, left_ast, token_list}
    else
      next_token = hd(token_list)
      next_precedence = get_infix_precedence(next_token)

      if next_precedence > precedence_context do
        operator_token = next_token
        rest_after_operator = tl(token_list)

        case parse_expression(rest_after_operator, next_precedence) do
          # The recursive call succeeded. This is the "happy path".
          {:ok, right_ast, rest_after_rhs} ->
            new_left_ast = AST.binary_op(left_ast, operator_token.type, right_ast)
            # Continue the loop as before.
            parse_infix_expression(rest_after_rhs, new_left_ast, precedence_context)

          # The recursive call failed to find a right-hand side.
          {:error, reason} ->
            # This is a syntax error. We stop parsing and pass the error up.
            {:error, reason}
        end
      else
        # The loop is done. The `left_ast` we've built up is the final expression.
        {:ok, left_ast, token_list}
      end
    end
  end

  defp parse_prefix_expression([%Token{type: :eof} | _rest]) do
    {:error, "Unexpected end of file, expected an expression"}
  end

  defp parse_prefix_expression([%Token{type: :left_paren} | rest]) do
    parse_grouped_expression(rest)
  end

  defp parse_prefix_expression([%Token{type: :integer, value: value} | rest]) do
    {:ok, AST.integer(value), rest}
  end

  defp parse_prefix_expression([%Token{type: :float, value: value} | rest]) do
    {:ok, AST.float(value), rest}
  end

  defp parse_prefix_expression([%Token{type: :identifier, value: value} | rest]) do
    {:ok, AST.identifier(value), rest}
  end

  defp parse_prefix_expression([%Token{type: :hexbyte, value: value} | rest]) do
    {:ok, AST.hexbyte(value), rest}
  end

  defp parse_prefix_expression([%Token{type: :base64, value: value} | rest]) do
    {:ok, AST.base64(value), rest}
  end

  defp parse_prefix_expression([%Token{type: :text, value: value} | rest]) do
    {:ok, AST.text(value), rest}
  end

  defp parse_prefix_expression([%Token{type: :interpolated_text, value: value} | rest]) do
    {:ok, AST.interpolated_text(value), rest}
  end

  defp parse_prefix_expression([%Token{type: :hole} | rest]) do
    {:ok, AST.hole(), rest}
  end

  # The catch-all error clause remains the same.
  defp parse_prefix_expression([unhandled | _]) do
    {:error, "Unexpected token at start of expression: #{Token.to_string(unhandled)}"}
  end

  defp parse_grouped_expression(token_list) do
    case parse_expression(token_list, 0) do
      {:ok, inner_ast, rest_after_inner} ->
        case rest_after_inner do
          [%Token{type: :right_paren} | rest_after_paren] ->
            {:ok, inner_ast, rest_after_paren}

          _ ->
            {:error, "Expected right parenthesis"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # =============================================================================
  # PRECEDENCE HELPER
  # =============================================================================

  # Returns the infix precedence (binding power) for a given token.
  # Higher numbers mean higher precedence.
  # Returns 0 if the token is not an infix operator.
  defp get_infix_precedence(%Token{type: type}) do
    case type do
      :semicolon -> 1
      # Precedence 2
      :equals -> 2
      # Precedence 3
      :colon -> 3
      # Precedence 4
      # |>
      :pipe_operator -> 4
      # Precedence 6
      # >>
      :pipe_forward -> 6
      # Precedence 7
      # ->
      :right_arrow -> 7
      # Precedence 8
      # ::
      :double_colon -> 8
      # Precedence 9
      # ++
      :double_plus -> 9
      # Precedence 10
      :plus -> 10
      :minus -> 10
      # Precedence 11
      # +<
      :append -> 11
      # >+
      :cons -> 11
      # Precedence 20
      :multiply -> 20
      :slash -> 20
      # Precedence 35
      :dot -> 35
      # Precedence 40 (This is a special case, handled implicitly by the parser loop)
      # We don't have a specific token for "App", so we don't list it here.

      # Default case for any token that is not an infix operator
      _ -> 0
    end
  end
end
