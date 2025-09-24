# lib/scrapex/ast/binding.ex
defmodule Scrapex.AST.Binding do
  @moduledoc "AST nodes for ScrapScript variable bindings"

  alias AST.{Type, Expression}

  @type simple_binding :: {:binding, name :: String.t(), value_expr :: Scrapex.AST.Expression.t()}
  @type typed_binding ::
          {:typed_binding, name :: String.t(), type_expr :: Type.t(),
           value_expr :: Expression.t()}

  @type type_binding ::
          {:type_binding, name :: String.t(), type_union :: Scrapex.AST.Type.type_union()}

  @type t :: simple_binding() | typed_binding() | type_binding()

  def binding(name, value_expr), do: {:binding, name, value_expr}

  def typed_binding(name, type_expr, value_expr),
    do: {:typed_binding, name, type_expr, value_expr}

  def type_binding(name, type_expr), do: {:typed_binding, name, type_expr}
end
