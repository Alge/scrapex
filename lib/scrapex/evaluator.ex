defmodule Scrapex.Evaluator do
  @moduledoc """
  ScrapScript expression evaluator.
  """

  require Logger
  alias Scrapex.{Value, Evaluator.Scope}

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
    Logger.debug("Evaluating node: #{inspect(ast_node)}")

    case ast_node do
      {:integer, value} ->
        {:ok, Value.integer(value)}

      {:float, value} ->
        {:ok, Value.float(value)}

      {:text, value} ->
        {:ok, Value.text(value)}

      {:variant, name, _} ->
        {:ok, Value.variant(name)}

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
        with {:ok, function_value} <- eval(func_expr, scope),
             {:ok, arg_value} <- eval(arg_expr, scope) do
          apply_function(function_value, arg_value)
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
             {:ok, result} <- Value.append(left_value, right_value) do
          {:ok, result}
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
    case eval_binding(binding, scope) do
      {:ok, new_scope} ->
        eval_binding(body, new_scope)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Regular bindings
  defp eval_binding({:binding, name, expression}, scope) do
    Logger.debug("Binding variable #{name}")
    Logger.debug("Evaluating expression to be bound: #{inspect(expression)}")

    case eval(expression, scope) do
      {:ok, value} ->
        Logger.debug("Binding'#{name}' =  #{inspect(value)}")
        new_scope = Scope.bind(scope, name, value)

        Logger.debug("New scope: #{inspect(new_scope)}")
        {:ok, new_scope}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Function applications

  defp apply_function({:function, {:pattern_match_expression, clauses}, closure_scope}, arg_value) do
    try_pattern_clauses(clauses, arg_value, closure_scope)
  end

  defp apply_function(non_function, _arg_value) do
    {:error, "Cannot apply non-function value: #{inspect(non_function)}"}
  end

  defp try_pattern_clauses([], _arg_value, _closure_scope) do
    {:error, "No pattern matched the argument"}
  end

  defp try_pattern_clauses([{:pattern_clause, pattern, body} | rest], arg_value, scope) do
    case pattern_matches(pattern, arg_value) do
      {:ok, bindings} ->
        new_scope = apply_bindings(bindings, scope)
        eval(body, new_scope)

      {:error, :no_match} ->
        try_pattern_clauses(rest, arg_value, scope)
    end
  end

  defp apply_bindings(bindings, scope) do
    Enum.reduce(bindings, scope, fn {name, value}, acc_scope ->
      Scope.bind(acc_scope, name, value)
    end)
  end

  defp pattern_matches({:identifier, name}, arg_value) do
    {:ok, [{name, arg_value}]}
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

  defp pattern_matches(_pattern, _arg_value) do
    {:error, :no_match}
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
end
