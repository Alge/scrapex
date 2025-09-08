defmodule Scrapex.AST.Program do
  alias Scrapex.AST.Expression
  @type t :: {:program, expressions :: [Expression.t()]}

  def new(expressions), do: {:program, expressions}
end
