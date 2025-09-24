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

      {:identifier, name} ->
        # Look up variable in scope!
        case Scope.get(scope, name) do
          {:ok, value} -> {:ok, value}
          {:error, :not_found} -> {:error, "Undefined variable: '#{name}'"}
        end

      {:binary_op, _left_node, :equals, _right_node} ->
        nil

      {:binary_op, left_node, :plus, right_node} ->
        with {:ok, left_value} <- eval(left_node, scope),
             {:ok, right_value} <- eval(right_node, scope),
             {:ok, result} <- Value.add(left_value, right_value) do
          {:ok, result}
        end

      {:binary_op, _left_node, :minus, _right_node} ->
        # TODO
        nil

      {:binary_op, _left_node, :mulptiply, _right_node} ->
        # TODO
        nil

      {:binary_op, _left_node, :slash, _right_node} ->
        # TODO
        nil

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

  # the binding is just another where clause, we need to loop a bit more?
  defp eval_binding({:where, _} = ast_node, scope) do
  end

  # Regular bindings
  defp eval_binding({:binding, name, expression}, scope) do
    Logger.info("Binding variable #{name}")

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
end
