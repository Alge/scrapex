defmodule Scrapex.AST.Pattern do
  @moduledoc "Pattern nodes in the AST"

  alias Scrapex.AST.{Identifier, Literal, Record}

  # =============================================================================
  # TYPES
  # =============================================================================

  # Basic patterns
  @type wildcard_pattern :: {:wildcard}

  # List patterns
  @type empty_list_pattern :: {:empty_list}
  @type regular_list_pattern :: {:regular_list_pattern, elements :: [t()]}
  @type concat_list_pattern :: {:concat_list_pattern, elements :: [t()], tail :: t()}
  @type cons_list_pattern :: {:cons_list_pattern, head :: t(), tail :: t()}

  @type list_pattern ::
          empty_list_pattern()
          | regular_list_pattern()
          | concat_list_pattern()
          | cons_list_pattern()

  # Other patterns
  @type variant_pattern :: {:variant_pattern, identifier :: Identifier.t(), patterns :: [t()]}
  @type text_pattern :: {:text_pattern, text :: Literal.text_literal(), pattern :: t()}

  # Union of all patterns
  @type t ::
          Literal.t()
          | Identifier.t()
          | wildcard_pattern()
          | list_pattern()
          | variant_pattern()
          | text_pattern()
          | Record.record_pattern()

  # =============================================================================
  # CONSTRUCTORS
  # =============================================================================

  @doc "Create a wildcard pattern"
  def wildcard(), do: {:wildcard}

  # List patterns
  @doc "Create an empty list pattern"
  def empty_list(), do: {:empty_list}

  @doc "Create a regular list pattern"
  def regular_list_pattern(elements), do: {:regular_list_pattern, elements}

  @doc "Create a concat list pattern"
  def concat_list_pattern(elements, tail), do: {:concat_list_pattern, elements, tail}

  @doc "Create a cons list pattern"
  def cons_list_pattern(head, tail), do: {:cons_list_pattern, head, tail}

  # Record patterns
  @doc "Create a record field pattern"
  def record_pattern_field(identifier, pattern), do: {:field, identifier, pattern}

  @doc "Create a record rest pattern"
  def record_rest(pattern), do: {:rest, pattern}

  @doc "Create a record pattern"
  def record_pattern(fields), do: {:record_pattern, fields}

  # Other patterns
  @doc "Create a variant pattern"
  def variant_pattern(identifier, patterns), do: {:variant_pattern, identifier, patterns}

  @doc "Create a text pattern"
  def text_pattern(text, pattern), do: {:text_pattern, text, pattern}
end
