# lib/scrapex/parser.ex

defmodule Scrapex.Parser do
  alias Scrapex.{AST, Token}

  @doc """
  The main entry point for the parser.
  Parses a list of tokens into a single expression AST.
  """
  def parse(token_list) when is_list(token_list) do
    # Handle the edge case of empty or effectively empty input.
    if token_list == [] or hd(token_list).type == :eof do
      {:error, "Empty input"}
    else
      # The main logic: parse one full expression, starting with precedence 0.
      case parse_expression(token_list, 0) do
        # The success case: we got an expression and the ONLY thing left is EOF.
        {:ok, expression_ast, [%Token{type: :eof} | _]} ->
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

  # =============================================================================
  # PRIVATE PARSING LOGIC
  # =============================================================================

  # --- Expression Orchestrator (Pratt Parser Core) ---

  defp parse_expression(token_list, precedence_context) do
    # Step 1: Always parse the left-hand/prefix part of the expression first.
    case parse_prefix_expression(token_list) do
      {:ok, left_ast, rest_after_prefix} ->
        # Step 2: Start the infix loop with the result from step 1.
        parse_infix_expression(rest_after_prefix, left_ast, precedence_context)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_infix_expression(token_list, left_ast, precedence_context) do
    if token_list == [] or hd(token_list).type == :eof do
      {:ok, left_ast, token_list}
    else
      next_token = hd(token_list)
      next_precedence = get_infix_precedence(next_token)

      cond do
        # There is currently nothing with higher precedence than 40, but let's check
        # anyways for completeness and to reduce risk of bugs in the future!
        can_start_function_argument?(next_token) and
            get_infix_precedence(:function_app) > precedence_context ->
          case parse_expression(token_list, get_infix_precedence(:function_arg)) do
            {:ok, expression, remaining_tokens} ->
              function_app = AST.function_app(left_ast, expression)
              parse_infix_expression(remaining_tokens, function_app, precedence_context)

            {:error, reason} ->
              {:error, reason}
          end

        next_precedence > precedence_context ->
          operator_token = next_token
          rest_after_operator = tl(token_list)

          case parse_expression(rest_after_operator, next_precedence) do
            {:ok, right_ast, rest_after_rhs} ->
              new_left_ast = AST.binary_op(left_ast, operator_token.type, right_ast)
              parse_infix_expression(rest_after_rhs, new_left_ast, precedence_context)

            {:error, reason} ->
              {:error, reason}
          end

        true ->
          {:ok, left_ast, token_list}
      end
    end
  end

  # --- Prefix Expression Dispatcher ---

  defp parse_prefix_expression([first_token | _] = token_list) do
    parse_prefix(first_token.type, token_list)
  end

  defp parse_prefix_expression([]) do
    {:error, "Unexpected end of file, expected an expression"}
  end

  # --- Prefix Expression Workers ---

  defp parse_prefix(:integer, [%Token{value: value} | rest]) do
    {:ok, AST.integer(value), rest}
  end

  defp parse_prefix(:float, [%Token{value: value} | rest]) do
    {:ok, AST.float(value), rest}
  end

  defp parse_prefix(:identifier, [%Token{value: value} | rest]) do
    {:ok, AST.identifier(value), rest}
  end

  defp parse_prefix(:hexbyte, [%Token{value: value} | rest]) do
    {:ok, AST.hexbyte(value), rest}
  end

  defp parse_prefix(:base64, [%Token{value: value} | rest]) do
    {:ok, AST.base64(value), rest}
  end

  defp parse_prefix(:text, [%Token{value: value} | rest]) do
    {:ok, AST.text(value), rest}
  end

  defp parse_prefix(:interpolated_text, [%Token{value: value} | rest]) do
    {:ok, AST.interpolated_text(value), rest}
  end

  defp parse_prefix(:hole, [_token | rest]) do
    {:ok, AST.hole(), rest}
  end

  defp parse_prefix(:left_paren, [_token | rest]) do
    parse_grouped_expression(rest)
  end

  # Handles prefix operators like `-` and `!`
  defp parse_prefix(type, token_list)
       when type in [:minus, :exclamation_mark, :hashtag, :rock, :at] do
    parse_unary_expression(token_list)
  end

  # The catch-all for any token type we don't know how to start an expression with.
  defp parse_prefix(_type, [token | _]) do
    {:error, "Unexpected token at start of expression: #{Token.to_string(token)}"}
  end

  # --- Prefix Expression Helpers ---

  defp parse_grouped_expression(token_list) do
    case parse_expression(token_list, 0) do
      {:ok, inner_ast, rest_after_inner} ->
        case rest_after_inner do
          [%Token{type: :right_paren} | rest_after_paren] ->
            {:ok, inner_ast, rest_after_paren}

          _ ->
            {:error, "Mismatched parentheses: expected ')'"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_unary_expression([operator_token | rest_of_tokens]) do
    # From the precedence table
    prefix_precedence = 30

    case parse_expression(rest_of_tokens, prefix_precedence) do
      {:ok, operand_ast, rest_after_operand} ->
        ast_node = AST.unary_op(operator_token.type, operand_ast)
        {:ok, ast_node, rest_after_operand}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # =============================================================================
  # PRECEDENCE HELPER
  # =============================================================================

  defp get_infix_precedence(:function_app), do: 30
  defp get_infix_precedence(:function_arg), do: 31

  defp get_infix_precedence(%Token{type: type}) do
    case type do
      :semicolon -> 1
      :equals -> 2
      :colon -> 3
      # |>
      :pipe_operator -> 4
      # >>
      :pipe_forward -> 6
      # ->
      :right_arrow -> 7
      # ::
      :double_colon -> 8
      # ++
      :double_plus -> 9
      :plus -> 10
      :minus -> 10
      # +<
      :append -> 11
      # >+
      :cons -> 11
      :multiply -> 20
      :slash -> 20
      :dot -> 35
      _ -> 0
    end
  end

  defp get_infix_precedence(_), do: 0

  defp can_start_prefix_expression?(%Token{type: token_type}) do
    AST.Literal.literal?(token_type) or
      token_type == :identifier or
      token_type == :left_paren or
      token_type in [:minus, :exclamation_mark, :hashtag, :rock, :at]
  end

  defp can_start_function_argument?(token) do
    can_start_prefix_expression?(token) and get_infix_precedence(token) == 0
  end
end
