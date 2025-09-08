defmodule Scrapex.AST.Identifier do
  @type t :: {:identifier, name :: String.t()}

  def new(name), do: {:identifier, name}
end
