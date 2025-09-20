# lib/scrapex/ast/binding.ex
defmodule Scrapex.AST.Binding do
  @moduledoc "AST nodes for ScrapScript variable bindings"

  @type simple_binding :: {:binding, name :: String.t(), value_expr :: Scrapex.AST.Expression.t()}

  @type t :: simple_binding()

  def binding(name, value_expr), do: {:binding, name, value_expr}
end
