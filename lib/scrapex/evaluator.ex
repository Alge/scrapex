defmodule Scrapex.Evaluator do
  @moduledoc """
  ScrapScript expression evaluator.
  """

  require Logger
  alias Scrapex.AST
  alias Scrapex.{Value, Evaluator.Scope}
  alias Scrapex.PrettyPrinter

  @spec eval(term()) :: {:ok, Value.t()} | {:error, String.t()}
  def eval(ast_node) do
    eval(ast_node, Scope.empty())
  end

  @doc """
  Evaluates an AST node in the given scope.
  Returns {:ok, value} on success, {:error, reason} on failure.
  """
  @spec eval(term(), Scope.t()) :: {:ok, Value.t()} | {:error, String.t()}
  def eval(ast_node, scope) do
    Logger.info("Evaluating\n#{PrettyPrinter.format(ast_node)}")
    Logger.info("Scope\n#{PrettyPrinter.format(scope)}")

    case ast_node do
      {:integer, value} ->
        {:ok, Value.integer(value)}

      {:float, value} ->
        {:ok, Value.float(value)}

      {:text, value} ->
        {:ok, Value.text(value)}

      {:variant, tag, payload_expr} ->
        # First, recursively evaluate the payload expression to get its value.
        with {:ok, payload_value} <- eval(payload_expr, scope) do
          # Then, use that resulting value to construct the final runtime variant.
          {:ok, Value.variant(tag, payload_value)}
        end

      {:hole} ->
        {:ok, Value.hole()}

      {:hexbyte, value} ->
        {:ok, Value.hexbyte(value)}

      {:base64, value} ->
        {:ok, Value.base64(value)}

      {:interpolated_text, segments} ->
        case eval_interpolated_segments(segments, scope) do
          {:ok, segments} -> {:ok, Value.text(Enum.join(segments))}
          {:error, reason} -> {:error, reason}
        end

      {:list_literal, elements} ->
        case eval_list_items(elements, scope, []) do
          {:ok, values} -> {:ok, Value.list(values)}
          {:error, reason} -> {:error, reason}
        end

      {:record_literal, fields} ->
        case eval_record_fields(fields, scope, []) do
          {:ok, fields} -> {:ok, Value.record(fields)}
          {:error, reason} -> {:error, reason}
        end

      {:identifier, name} ->
        # Look up variable in scope!
        case Scope.get(scope, name) do
          {:ok, value} -> {:ok, value}
          {:error, :not_found} -> {:error, "Undefined variable: '#{name}'"}
        end

      {:field_access, record_expression, name} ->
        case eval(record_expression, scope) do
          {:ok, {:record, fields}} ->
            Logger.info("Trying to find #{inspect(name)} in #{inspect(fields)}")

            case List.keyfind(fields, name, 0) do
              {^name, value} -> {:ok, value}
              nil -> {:error, "Field '#{name}' not found in record"}
            end

          {:ok, other_value} ->
            {:error, "Cannot access field on non-record '#{inspect(other_value)}'"}

          {:error, reason} ->
            {:error, reason}
        end

      {:pattern_match_expression, clauses} ->
        # Create a function value with current scope captured as closure
        {:ok, Value.function({:pattern_match_expression, clauses}, scope)}

      {:function_app, func_expr, arg_expr} ->
        Logger.debug("About to apply function")

        with {:ok, function_value} <- eval(func_expr, scope),
             {:ok, arg_value} <- eval(arg_expr, scope) do
          Logger.debug("Function: #{inspect(function_value)}")
          Logger.debug("Argument: #{inspect(arg_value)}")
          result = apply_function(function_value, arg_value)
          Logger.debug("Application result: #{inspect(result)}")
          result
        end

      {:unary_op, :minus, operand} ->
        case eval(operand, scope) do
          {:ok, value} ->
            case Value.negate(value) do
              {:ok, result} -> {:ok, result}
              {:error, reason} -> {:error, reason}
            end

          {:error, reason} ->
            {:error, reason}
        end

      # Fallback base case for unary ops
      {:unary_op, operator, operand} ->
        {:error, "Don't know how to apply #{inspect(operator)} to #{inspect(operand)}"}

      {:binary_op, left_node, :plus, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.add(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, left_node, :minus, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.subtract(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, left_node, :multiply, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.multiply(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, left_node, :slash, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.divide(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, left_node, :double_plus, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.append_text(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, left_node, :append, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.append_to_list(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, left_node, :cons, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.cons(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, left_node, :double_equals, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.equal(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, left_node, :not_equals, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.not_equal(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, left_node, :less_than, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.less_than(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, left_node, :greater_than, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.greater_than(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, left_node, :pipe_operator, right_node} ->
        with {:ok, value} <- eval(left_node, scope),
             {:ok, func} <- eval(right_node, scope) do
          apply_function(func, value)
        end

      {:where, body, binding_ast} ->
        Logger.debug("Found a where clause!")
        Logger.debug("Body: #{inspect(body)}")
        Logger.debug("Binding: #{inspect(binding_ast)}")
        # First evaluate the binding AST to get the scope
        case eval_binding(binding_ast, scope) do
          {:ok, modified_scope} ->
            # Now that we have the modified scope we can evaluate the body
            eval(body, modified_scope)

          {:error, reason} ->
            {:error, reason}
        end

      # Catch-all for unimplemented AST nodes
      other ->
        {:error, "Unimplemented AST node: #{inspect(other)}"}
    end
  end

  # Evaluate list items
  defp eval_list_items([], _scope, acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp eval_list_items([element | rest], scope, acc) do
    case eval(element, scope) do
      {:ok, value} -> eval_list_items(rest, scope, [value | acc])
      {:error, reason} -> {:error, reason}
    end
  end

  # Evaluate record fields
  defp eval_record_fields([], _scope, acc) do
    deduplicated =
      acc
      |> Enum.uniq_by(fn {name, _value} -> name end)
      |> Enum.reverse()

    {:ok, deduplicated}
  end

  defp eval_record_fields([{:expression_field, name, value_expr} | rest], scope, acc)
       when is_binary(name) do
    case eval(value_expr, scope) do
      {:ok, value} -> eval_record_fields(rest, scope, [{name, value} | acc])
      {:error, reason} -> {:error, reason}
    end
  end

  defp eval_record_fields([{:spread_expression, var_name} | rest], scope, acc) do
    case Scope.get(scope, var_name) do
      {:ok, {:record, fields}} ->
        # Add spread fields to accumulator, then continue with remaining fields
        new_acc = Enum.reverse(fields) ++ acc
        eval_record_fields(rest, scope, new_acc)

      {:ok, other_value} ->
        {:error, "Cannot spread non-record value: #{inspect(other_value)}"}

      {:error, :not_found} ->
        {:error, "Undefined variable: '#{var_name}'"}
    end
  end

  # Nested bindings, both "body" and "binding" are bindings,
  # but "body" can have dependencies inside "binding", so that
  # needs to be evaluated first
  defp eval_binding({:where, body, binding}, scope) do
    Logger.debug(
      "Entering eval_binding(:where). First evaluating OUTER binding: #{inspect(binding)}"
    )

    case eval_binding(binding, scope) do
      {:ok, new_scope} ->
        Logger.debug("OUTER binding succeeded. Now evaluating INNER binding: #{inspect(body)}")
        eval_binding(body, new_scope)

      {:error, reason} ->
        Logger.debug("OUTER binding failed.")
        {:error, reason}
    end
  end

  # Binding of functions
  defp eval_binding({:binding, name, {:pattern_match_expression, _} = pme}, scope) do
    Logger.debug("Entering eval_binding(:binding) for a NAMED FUNCTION: '#{name}'")

    # Create a unified function value that ALWAYS remembers its binding name.
    # The closure is the scope that exists BEFORE this binding.
    function_value = Value.function(name, pme, scope)
    Logger.debug("Created function value: #{inspect(function_value)}")

    new_scope = Scope.bind(scope, name, function_value)
    Logger.debug("Returning new scope with '#{name}' bound.")
    {:ok, new_scope}
  end

  # Regular bindings
  defp eval_binding({:binding, name, expression}, scope) do
    Logger.debug("Entering eval_binding(:binding) for a VARIABLE: '#{name}'")
    Logger.debug("Evaluating expression to be bound: #{inspect(expression)}")

    case eval(expression, scope) do
      {:ok, value} ->
        Logger.debug("Binding '#{name}' =  #{inspect(value)}")
        new_scope = Scope.bind(scope, name, value)

        Logger.debug("Returning new scope with '#{name}' bound.")
        {:ok, new_scope}

      {:error, reason} ->
        Logger.debug("Expression evaluation for '#{name}' failed.")
        {:error, reason}
    end
  end

  defp eval_binding({:typed_binding, name, _type_expr, expresssion}, scope) do
    # Type checking is done in a separate step
    eval_binding(AST.binding(name, expresssion), scope)
  end

  # Function applications

  # Anonymous function
  defp apply_function(
         {:function, nil, {:pattern_match_expression, clauses}, closure_scope},
         arg_value
       ) do
    try_pattern_clauses(clauses, arg_value, closure_scope)
  end

  # Named function, this could be recursive!
  defp apply_function(
         {:function, name, {:pattern_match_expression, clauses}, closure_scope} = func,
         arg_value
       ) do
    # Add the reference to itself to the scope
    tmp_scope = Scope.bind(closure_scope, name, func)
    try_pattern_clauses(clauses, arg_value, tmp_scope)
  end

  defp apply_function(non_function, _arg_value) do
    {:error, "Cannot apply non-function value: #{inspect(non_function)}"}
  end

  defp try_pattern_clauses([], _arg_value, _closure_scope) do
    Logger.debug("No patterns matched!")
    {:error, "No pattern matched the argument"}
  end

  defp try_pattern_clauses([{:pattern_clause, pattern, body} | rest], arg_value, scope) do
    Logger.debug("Trying pattern: #{inspect(pattern)} against #{inspect(arg_value)}")

    case pattern_matches(pattern, arg_value) do
      {:ok, bindings} ->
        Logger.debug("Pattern matched! Bindings: #{inspect(bindings)}")
        # Make sure we don't bind a name to two different values!
        case check_binding_consistency(bindings) do
          :ok ->
            # back to simple version
            new_scope = apply_bindings(bindings, scope)
            eval(body, new_scope)

          # Variable conflicts, this is not a match. Try next pattern
          {:error, :variable_conflict} ->
            try_pattern_clauses(rest, arg_value, scope)
        end

      # Not match, try next pattern
      {:error, :no_match} ->
        try_pattern_clauses(rest, arg_value, scope)
    end
  end

  defp apply_bindings(bindings, scope) do
    Enum.reduce(bindings, scope, fn {name, value}, acc_scope ->
      Scope.bind(acc_scope, name, value)
    end)
  end

  defp check_binding_consistency(bindings) do
    check_bindings_recursive(bindings, %{})
  end

  defp check_bindings_recursive([], _seen), do: :ok

  defp check_bindings_recursive([{name, value} | rest], seen) do
    case Map.get(seen, name) do
      nil ->
        # First time seeing this variable
        check_bindings_recursive(rest, Map.put(seen, name, value))

      ^value ->
        # Same variable, same value - ok
        check_bindings_recursive(rest, seen)

      _other_value ->
        # Same variable, different value - conflict
        {:error, :variable_conflict}
    end
  end

  defp pattern_matches({:text_pattern, {:text, prefix}, rest_pattern}, {:text, value}) do
    if String.starts_with?(value, prefix) do
      {_prefix_part, rest_of_string} = String.split_at(value, String.length(prefix))

      # Recursively match the `rest_pattern` against the correctly extracted remainder.
      pattern_matches(rest_pattern, Value.text(rest_of_string))
    else
      {:error, :no_match}
    end
  end

  defp pattern_matches({:identifier, name}, arg_value) do
    {:ok, [{name, arg_value}]}
  end

  defp pattern_matches({:variant, name, _}, {:variant, name, nil}) do
    # It's a match if the names are the same.
    # We ignore the payload (`_`) from the AST node.
    {:ok, []}
  end

  defp pattern_matches(
         {:variant_pattern, {:identifier, p_tag}, [p_payload_pattern]},
         {:variant, v_tag, v_payload}
       )
       when p_tag == v_tag do
    # This is the main case for a pattern with a payload, like `#some v`.
    # It should FAIL if the value's payload is a hole.
    if v_payload == Value.hole() do
      {:error, :no_match}
    else
      pattern_matches(p_payload_pattern, v_payload)
    end
  end

  defp pattern_matches(
         {:variant_pattern, {:identifier, p_tag}, []},
         {:variant, v_tag, v_payload}
       )
       when p_tag == v_tag do
    # This is the case for a pattern with no payload, like `#none`.
    # It should ONLY succeed if the value's payload is a hole.
    if v_payload == Value.hole() do
      {:ok, []}
    else
      {:error, :no_match}
    end
  end

  # Add a catch-all for when tags don't match
  defp pattern_matches({:variant_pattern, _, _}, {:variant, _, _}) do
    {:error, :no_match}
  end

  defp pattern_matches({:wildcard}, _arg_value) do
    {:ok, []}
  end

  defp pattern_matches({:empty_list}, {:list, []}) do
    {:ok, []}
  end

  defp pattern_matches(value, value) do
    {:ok, []}
  end

  defp pattern_matches({:regular_list_pattern, patterns}, {:list, values}) do
    case match_pattern_list(patterns, values, []) do
      {:ok, bindings, []} -> {:ok, bindings}
      {:ok, _, _} -> {:error, :no_match}
      {:error, reason} -> {:error, reason}
    end
  end

  defp pattern_matches({:cons_list_pattern, _head_pattern, _tail_pattern}, {:list, []}) do
    {:error, :no_match}
  end

  defp pattern_matches(
         {:cons_list_pattern, head_pattern, tail_pattern},
         {:list, [head | tail]}
       ) do
    with {:ok, first_bindings} <- pattern_matches(head_pattern, head),
         {:ok, second_bindings} <- pattern_matches(tail_pattern, Value.list(tail)) do
      {:ok, Enum.concat(first_bindings, second_bindings)}
    end
  end

  defp pattern_matches(
         {:concat_list_pattern, patterns, rest_pattern},
         {:list, values}
       ) do
    case match_pattern_list(patterns, values, []) do
      {:ok, bindings, remaining_items} ->
        case pattern_matches(rest_pattern, Value.list(remaining_items)) do
          {:ok, rest_bindings} ->
            {:ok, bindings ++ rest_bindings}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp pattern_matches({:record_pattern, pattern_fields}, {:record, record_fields}) do
    # First separate the rest pattern(s) from the explisit patterns.
    # The rest pattern(s) are handled separatly from the explicit ones
    {rest_patterns, explicit_patterns} =
      Enum.split_with(pattern_fields, fn
        {:record_rest, _} -> true
        _ -> false
      end)

    case match_pattern_record(explicit_patterns, record_fields) do
      {:ok, bindings, remaining_fields} ->
        # Time to handle th rest pattern if available
        case rest_patterns do
          # No rest pattern, we need to make sure there are no record fields left!
          [] ->
            # "open" record bindings. We don't care if there are more keys,
            # just that all patterns we have provided matched
            {:ok, bindings}

          # "Closed" record bindings. if we want to match exactly on the record content
          # case remaining_fields do
          #   [] -> {:ok, bindings}
          #   _ -> {:error, :no_match}
          # end

          # Make sure we only have one rest pattern
          [_, _ | _] ->
            {
              :error,
              "Only one rest pattern allowed"
            }

          # Add the rest pattern binding
          [{:record_rest, rest_name}] ->
            {:ok, [{rest_name, Value.record(remaining_fields)} | bindings]}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp pattern_matches(_pattern, _arg_value) do
    {:error, :no_match}
  end

  # Entry point for matching explicit record patterns
  defp match_pattern_record(explicit_patterns, value_fields) do
    match_pattern_record(explicit_patterns, value_fields, [])
  end

  # Base case, return the bindings and remaining fields
  defp match_pattern_record([], fields_left, bindings) do
    {:ok, Enum.reverse(bindings), fields_left}
  end

  # More pattern fields, but no record fields left to match against
  defp match_pattern_record(_pattern_fields, [], _bindings) do
    {:error, :no_match}
  end

  # Recursive part, make sure there is a value field for each pattern field
  defp match_pattern_record(
         [{:pattern_field, name, pattern} | remaining_patterns],
         value_fields,
         bindings
       ) do
    # First make sure there is a field with the same key in the value fields

    case List.keyfind(value_fields, name, 0) do
      {_key, value_expression} ->
        case pattern_matches(pattern, value_expression) do
          {:ok, new_bindings} ->
            # Remove the field from the value fields list as we have matched against it
            match_pattern_record(
              remaining_patterns,
              List.keydelete(value_fields, name, 0),
              new_bindings ++ bindings
            )

          {:error, reason} ->
            {:error, reason}
        end

      nil ->
        {:error, :no_match}
    end
  end

  # no patterns left, but maybe remaining list items
  defp match_pattern_list([], remaining_items, bindings) do
    {:ok, Enum.reverse(bindings), remaining_items}
  end

  # Patterns left, but no list items
  defp match_pattern_list([_ | _], [], _bindings) do
    {:error, :no_match}
  end

  defp match_pattern_list([pattern | rest_patterns], [value | rest_values], bindings) do
    case pattern_matches(pattern, value) do
      {:ok, new_bindings} ->
        match_pattern_list(rest_patterns, rest_values, new_bindings ++ bindings)

      {:error, :no_match} ->
        {:error, :no_match}
    end
  end

  ### Helper for evaluating interpolated text. Takes in a list of segments,
  ### and returns a list of strings

  defp eval_interpolated_segments(segments, scope) do
    eval_interpolated_segments(segments, scope, [])
  end

  defp eval_interpolated_segments([], _scope, acc) do
    {:ok, Enum.reverse(acc)}
  end

  defp eval_interpolated_segments([text | remaining_segments], scope, acc) when is_binary(text) do
    eval_interpolated_segments(remaining_segments, scope, [text | acc])
  end

  defp eval_interpolated_segments([expr | remaining_segments], scope, acc) do
    case eval(expr, scope) do
      {:ok, {:text, value}} ->
        eval_interpolated_segments(remaining_segments, scope, [value | acc])

      {:ok, value} ->
        {:error, "Cannot use #{inspect(value)} in interpolated text"}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
