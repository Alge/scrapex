defmodule Scrapex.AST.Program do
  alias Scrapex.AST.Expression
  @type t :: {:program, expressions :: [Expression.t()]}

  def new(expressions), do: {:program, expressions}
end

defmodule Scrapex.AST.Identifier do
  @type t :: {:identifier, name :: String.t()}

  def new(name), do: {:identifier, name}
end
