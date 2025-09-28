defmodule Scrapex.AST.Record do
  @moduledoc "AST nodes for ScrapScript records."

  alias Scrapex.AST.Expression
  alias Scrapex.AST.Pattern

  # --- TYPESPECS ---
  @type record_expression_field :: {:expression_field, String.t(), Expression.t()}
  @type record_pattern_field :: {:pattern_field, String.t(), Pattern.t()}

  @type spread_expression :: {:spread_expression, expression :: Expression.t()}
  @type record_rest :: {:record_rest, String.t()}

  @type record_literal ::
          {:record_literal, fields :: [record_expression_field() | spread_expression()]}
  @type record_pattern :: {:record_pattern, fields :: [record_pattern_field() | record_rest()]}

  # --- CONSTRUCTORS ---
  def record_literal(fields), do: {:record_literal, fields}
  def record_pattern(fields), do: {:record_pattern, fields}
  def spread_expression(expression), do: {:spread_expression, expression}
  def record_rest(pattern) when is_binary(pattern), do: {:record_rest, pattern}

  def record_expression_field(key, expression) when is_binary(key),
    do: {:expression_field, key, expression}

  def record_pattern_field(key, pattern) when is_binary(key), do: {:pattern_field, key, pattern}
end
