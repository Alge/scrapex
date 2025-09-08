defmodule Scrapex.Parser do
  alias Scrapex.{Token, AST}

  def parse_program([]) do
    {:error, "Empty input"}
  end

  def parse_program([%Token{type: :eof}]) do
    {:error, "Empty input"}
  end

  def parse_program(token_list) when is_list(token_list) do
    parse_program(token_list, [])
  end

  def parse_program(token_list, expressions) when is_list(token_list) when is_list(expressions) do
    case token_list do
      [%Token{type: :semicolon} | rest] ->
        parse_program(rest, expressions)

      [%Token{type: :eof} | _] ->
        expressions = expressions |> Enum.reverse()
        program_node = AST.program(expressions)
        {:ok, program_node}

      _ ->
        case parse_expression(token_list, 0) do
          {:ok, expression_ast, rest} ->
            parse_program(rest, [expression_ast | expressions])

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

  def parse_infix_expression(token_list, left_ast, precedence_context) do
    # Before we do anything, check if we're at the end of the file.
    # This handles the case where the prefix expression is the last thing.
    if token_list == [] or hd(token_list).type == :eof do
      {:ok, left_ast, token_list}
    else
      # We can safely peek the next token as we have checked
      # that it exists and is not a :eof token
      next_token = hd(token_list)

      # Find out the precedence for the next (probable) operator
      next_precedence = get_infix_precedence(next_token)

      # The next operator is stronger than the previous, let's parse it!
      if next_precedence > precedence_context do
        operator_token = next_token
        # Pop the token from the list
        rest_after_operator = tl(token_list)

        # Recursively find the right side of the expression
        {:ok, right_ast, right_after_rhs_expression} =
          parse_expression(rest_after_operator, next_precedence)

        infix_operation = AST.infix_operation(operator_token.type, right_ast)

        new_left_ast = AST.expression(left_ast, infix_operation)

        parse_infix_expression(right_after_rhs_expression, new_left_ast, precedence_context)
      else
        # The next operator is weaker than us, let's return here
        # There is nothing more for us to do right now.
        {:ok, left_ast, token_list}
      end
    end
  end

  defp parse_prefix_expression([%Token{type: :integer, value: value} | rest]) do
    prefix_node = AST.integer(value)
    ast_node = AST.expression(prefix_node, nil)
    {:ok, ast_node, rest}
  end

  defp parse_prefix_expression([%Token{type: :float, value: value} | rest]) do
    prefix_node = AST.float(value)
    ast_node = AST.expression(prefix_node, nil)
    {:ok, ast_node, rest}
  end

  defp parse_prefix_expression([%Token{type: :identifier, value: value} | rest]) do
    prefix_node = AST.identifier(value)
    ast_node = AST.expression(prefix_node, nil)
    {:ok, ast_node, rest}
  end

  defp parse_prefix_expression([%Token{type: :hexbyte, value: value} | rest]) do
    prefix_node = AST.hexbyte(value)
    ast_node = AST.expression(prefix_node, nil)
    {:ok, ast_node, rest}
  end

  defp parse_prefix_expression([%Token{type: :base64, value: value} | rest]) do
    prefix_node = AST.base64(value)
    ast_node = AST.expression(prefix_node, nil)
    {:ok, ast_node, rest}
  end

  defp parse_prefix_expression([%Token{type: :text, value: value} | rest]) do
    prefix_node = AST.text(value)
    ast_node = AST.expression(prefix_node, nil)
    {:ok, ast_node, rest}
  end

  defp parse_prefix_expression([%Token{type: :interpolated_text, value: value} | rest]) do
    prefix_node = AST.interpolated_text(value)
    ast_node = AST.expression(prefix_node, nil)
    {:ok, ast_node, rest}
  end

  defp parse_prefix_expression([%Token{type: :hole} | rest]) do
    prefix_node = AST.hole()
    ast_node = AST.expression(prefix_node, nil)
    {:ok, ast_node, rest}
  end

  # The catch-all error clause remains the same.
  defp parse_prefix_expression([unhandled | _]) do
    {:error, "Unexpected token at start of expression: #{Token.to_string(unhandled)}"}
  end

  # =============================================================================
  # PRECEDENCE HELPER
  # =============================================================================

  # Returns the infix precedence (binding power) for a given token.
  # Higher numbers mean higher precedence.
  # Returns 0 if the token is not an infix operator.
  defp get_infix_precedence(%Token{type: type}) do
    case type do
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
