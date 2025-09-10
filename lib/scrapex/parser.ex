# lib/scrapex/parser.ex
require Logger

defmodule Scrapex.Parser do
  alias Scrapex.{AST, Token}

  @doc """
  The main entry point for the parser.
  Parses a list of tokens into a single expression AST.
  """
  def parse(token_list) when is_list(token_list) do
    Logger.debug("Parser starting. Input tokens: #{inspect(token_list, pretty: true)}")
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
        next_token.type == :colon and next_precedence > precedence_context ->
          rest_after_colon = tl(token_list)

          # Peek ahead to see if the RHS is a variant list (starts with '#')
          next_is_hashtag =
            case rest_after_colon do
              [%Token{type: :hashtag} | _] -> true
              _ -> false
            end

          # A type declaration must be of the form `identifier : #variant...`
          case {left_ast, next_is_hashtag} do
            # This is the type declaration case we want to handle
            {{:identifier, name}, true} ->
              case parse_type_union_as_expression(rest_after_colon) do
                {:ok, {:type_union, variants}, remaining_tokens} ->
                  type_decl = AST.type_declaration(name, variants)
                  parse_infix_expression(remaining_tokens, type_decl, precedence_context)

                {:error, reason} ->
                  {:error, reason}
              end

            # Fallback to the original type annotation logic for all other cases
            _ ->
              case parse_expression(rest_after_colon, next_precedence) do
                {:ok, type_ast, remaining_tokens} ->
                  type_annotation = AST.type_annotation(left_ast, type_ast)
                  parse_infix_expression(remaining_tokens, type_annotation, precedence_context)

                {:error, reason} ->
                  {:error, reason}
              end
          end

        # There is currently nothing with higher precedence than 40, but let'readabilitys check
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

  # --- Extraction of type unions ---

  defp can_start_variant_payload?(%Token{type: type}) do
    # Only allow certain tokens to start a payload
    type in [:left_paren, :identifier, :integer, :float, :text] or
      AST.Literal.literal?(type)
  end

  defp parse_type_union_as_expression(token_list) do
    case parse_type_union(token_list, []) do
      {:ok, variants, remaining_tokens} ->
        type_union = AST.type_union(variants)
        {:ok, type_union, remaining_tokens}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_type_union([first_token | [second_token | rest]], variants)
       when first_token.type == :hashtag and second_token.type == :identifier do
    name = second_token.value

    case try_parse_variant_payload(rest) do
      {:ok, expression, remaining} ->
        variant = AST.variant(name, expression)
        parse_type_union(remaining, [variant | variants])

      {:no_payload, remaining} ->
        variant = AST.variant(name, AST.hole())
        parse_type_union(remaining, [variant | variants])

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_type_union(token_list, variants) do
    {:ok, Enum.reverse(variants), token_list}
  end

  # Add the missing empty list handler
  defp try_parse_variant_payload([]) do
    {:no_payload, []}
  end

  defp try_parse_variant_payload([next_token | _] = tokens) do
    if can_start_variant_payload?(next_token) do
      case parse_expression(tokens, 8) do
        {:ok, expression, remaining} ->
          {:ok, expression, remaining}

        {:error, _} ->
          {:no_payload, tokens}
      end
    else
      {:no_payload, tokens}
    end
  end

  # --- Prefix Expression Dispatcher ---

  defp parse_prefix_expression([first_token | _] = token_list) do
    parse_prefix(first_token.type, token_list)
  end

  defp parse_prefix_expression([]) do
    {:error, "Unexpected end of file, expected an expression"}
  end

  # --- Pattern match dispatcher ---

  defp can_start_pattern?(%Token{type: type, value: _}) do
    AST.literal?(type) or type in [:identifier, :left_bracket, :left_brace, :hashtag]
  end

  defp parse_pattern([%Token{type: :identifier, value: "_"} | rest]) do
    {:ok, AST.wildcard(), rest}
  end

  defp parse_pattern([token | _] = token_list) do
    # Check if the token is allowed in a pattern context.
    if can_start_pattern?(token) do
      # The prefix parser will return {:ok, ast, rest_of_tokens}.
      # This is exactly the signature that `parse_pattern` needs to return.
      parse_prefix_expression(token_list)
    else
      {:error, "Invalid token at start of pattern: #{Token.to_string(token)}"}
    end
  end

  defp parse_pattern([]), do: {:error, "Unexpected end of input, expected a pattern"}

  defp parse_pattern_match_clauses(
         [%Token{type: :pipe} | rest],
         acc
       ) do
    case(parse_pattern(rest)) do
      {:ok, pattern, [%Token{type: :right_arrow} | remaining_tokens]} ->
        case parse_expression(remaining_tokens, 0) do
          {:ok, expression, tokens_after_expression} ->
            # We need a type for this right? We don't have a "clause" pattern
            pattern_match_clause = AST.pattern_clause(pattern, expression)

            parse_pattern_match_clauses(tokens_after_expression, [
              pattern_match_clause | acc
            ])

          {:error, reason} ->
            {:error, reason}
        end

      {:ok, _pattern, _} ->
        {:error, "Expected right arrow ('->')"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_pattern_match_clauses(
         token_list,
         acc
       ) do
    {:ok, Enum.reverse(acc), token_list}
  end

  # Parsing of list literals

  # Handle empty lists
  defp parse_list_literal([%Token{type: :right_bracket} | rest]) do
    {:ok, AST.list_literal([]), rest}
  end

  # Handle lists with content
  defp parse_list_literal(token_list) do
    case parse_list_elements(token_list, []) do
      {:ok, elements, rest} -> {:ok, AST.list_literal(elements), rest}
      {:error, reason} -> {:error, reason}
    end
  end

  # Extract all elements from a list
  defp parse_list_elements(token_list, acc) do
    case parse_expression(token_list, 0) do
      {:ok, expression, [%Token{type: :comma} | rest]} ->
        # We have more items to parse, let's recurse
        parse_list_elements(rest, [expression | acc])

      {:ok, expression, [%Token{type: :right_bracket} | rest]} ->
        # We have reached the end, time to return the reversed acc
        {:ok, Enum.reverse([expression | acc]), rest}

      {:ok, _expression, [token | _rest]} ->
        # Got an unexpected token
        {:error, "Got an unexpected token: #{Token.to_string(token)}, expected ',' or ']'"}

      # We failed parsing the expression!
      {:error, reason} ->
        {:error, reason}
    end
  end

  # --- Prefix Expression Workers ---
  defp parse_prefix(:hashtag, token_list) do
    # Parse type union starting with #
    parse_type_union_as_expression(token_list)
  end

  defp parse_prefix(:pipe, token_list) do
    case parse_pattern_match_clauses(token_list, []) do
      {:ok, [], _} ->
        {:error, "Pattern match expression cannot be empty"}

      {:ok, clauses, remaining_tokens} ->
        ast_node = AST.pattern_match_expression(clauses)
        {:ok, ast_node, remaining_tokens}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_prefix(:left_bracket, [%Token{value: value} | rest]) do
    parse_list_literal(rest)
  end

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

  # Handle "()"
  defp parse_grouped_expression([%Token{type: :right_paren} | rest]) do
    {:ok, AST.hole(), rest}
  end

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
