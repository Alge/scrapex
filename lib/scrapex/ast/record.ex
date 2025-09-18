defmodule Scrapex.AST.Record do
  @moduledoc "AST nodes for ScrapScript records."

  alias Scrapex.AST.Identifier
  alias Scrapex.AST.Expression
  alias Scrapex.AST.Pattern

  # --- TYPESPECS ---
  @type expression_field :: {:expression_field, Identifier.t(), Expression.t()}
  @type pattern_field :: {:pattern_field, Identifier.t(), Pattern.t()}

  @type spread_expression :: {:spread_expression, expression :: Expression.t()}
  @type record_rest :: {:record_rest, Pattern.t()}

  @type record_literal :: {:record_literal, fields :: [expression_field() | spread_expression()]}
  @type record_pattern :: {:record_pattern, fields :: [pattern_field() | record_rest()]}

  # --- CONSTRUCTORS ---
  def record_literal(fields), do: {:record_literal, fields}
  def record_pattern(fields), do: {:record_pattern, fields}
  def spread_expression(expression), do: {:spread_expression, expression}
  def record_rest(pattern), do: {:record_rest, pattern}
  def record_expression_field(key, expression), do: {:expression_field, key, expression}
  def record_pattern_field(key, pattern), do: {:pattern_field, key, pattern}
end
