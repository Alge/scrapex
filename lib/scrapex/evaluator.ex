defmodule Scrapex.Evaluator do
  @moduledoc """
  ScrapScript expression evaluator.
  """

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

        # TODO
        nil

      {:binary_op, _left_node, :minus, _right_node} ->
        # TODO
        nil

      {:binary_op, _left_node, :mulptiply, _right_node} ->
        # TODO
        nil

      {:binary_op, _left_node, :slash, _right_node} ->
        # TODO
        nil

      # Catch-all for unimplemented AST nodes
      other ->
        {:error, "Unimplemented AST node: #{inspect(other)}"}
    end
  end
end
