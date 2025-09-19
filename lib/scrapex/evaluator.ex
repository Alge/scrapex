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

      # Catch-all for unimplemented AST nodes
      other ->
        {:error, "Unimplemented AST node: #{inspect(other)}"}
    end
  end
end
