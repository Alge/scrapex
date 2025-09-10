defmodule Scrapex.AST.Identifier do
  @type t :: {:identifier, name :: String.t()}

  def new(name), do: {:identifier, name}

  def identifier?({:identifier, _}), do: true
  def identifier?(_), do: false
end
