defmodule Scrapex.AST.Type do
  @moduledoc """
  Defines the AST nodes for the ScrapScript Type System.
  """

  alias Scrapex.AST.Identifier
  alias Scrapex.AST

  # =============================================================================
  # TYPESPECS
  # =============================================================================

  @type variant :: {:variant, name :: String.t(), payload :: AST.astnode()}
  @type type_union :: {:type_union, variants :: [variant()]}

  @typedoc "A simple variant used as a value, e.g., #true"
  @type variant_literal :: {:variant_literal, identifier :: Identifier.t()}

  @typedoc "A function type, e.g., int -> string"
  @type function_type :: {:function_type, from :: t(), to :: t()}

  @typedoc "A field within a record type, e.g., name : text"
  @type record_type_field :: {Identifier.t(), t()}

  @typedoc "A record type definition, e.g., { name : text, age : int }"
  @type record_type :: {:record_type, fields :: [record_type_field()]}

  @typedoc "The node for a type annotation, e.g., x : int"
  @type type_annotation ::
          {:type_annotation, expression :: Scrapex.AST.Expression.t(), type :: t()}

  @type t ::
          Identifier.t()
          | variant()
          | type_union()
          | variant_literal()
          | function_type()
          | record_type()

  # =============================================================================
  # CONSTRUCTORS
  # =============================================================================

  def variant(name), do: {:variant, name, AST.hole()}
  def variant(name, payload), do: {:variant, name, payload}
  def type_union(variants), do: {:type_union, variants}
  def variant_literal(identifier), do: {:variant_literal, identifier}
  def function_type(from, to), do: {:function_type, from, to}
  def record_type(fields), do: {:record_type, fields}
  def type_annotation(expression, type), do: {:type_annotation, expression, type}
end
