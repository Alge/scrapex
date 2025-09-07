defmodule Scrapex.AST.Type do
  @moduledoc """
  Defines the AST nodes for the ScrapScript Type System.
  """

  alias Scrapex.AST.Identifier

  # =============================================================================
  # TYPESPECS - The structure of our AST nodes
  # =============================================================================

  @doc "A simple variant used as a value, e.g., #true"
  @type variant_literal :: {:variant_literal, identifier :: Identifier.t()}

  @doc "A function type, e.g., int -> string. The structure is recursive."
  @type function_type :: {:function_type, from :: t(), to :: t()}

  @doc "A field within a record type, e.g., name : text"
  @type record_type_field :: {Identifier.t(), t()}

  @doc "A record type definition, e.g., { name : text, age : int }"
  @type record_type :: {:record_type, fields :: [record_type_field()]}

  @doc """
  A type expression can be a simple name, a function, or a record.
  This corresponds to the EBNF rule:
  type_expression ::= primary_type_expression ["->" type_expression]
  """
  @type t :: Identifier.t() | function_type() | record_type()

  @doc "A single variant in a type definition, e.g., #Some a"
  @type variant_declaration ::
          {:variant_declaration, identifier :: Identifier.t(), carries :: [t()]}

  @doc "The full definition for a type, e.g., a => #Some a | #None"
  @type type_definition ::
          {:type_definition, generic_params :: [Identifier.t()],
           variants :: [variant_declaration()]}

  @doc "The node for a type annotation, e.g., x : int"
  @type type_annotation ::
          {:type_annotation, expression :: Scrapex.AST.Expression.t(), type :: type_definition()}

  # =============================================================================
  # CONSTRUCTORS - Helper functions to build the nodes
  # =============================================================================

  def variant_literal(identifier), do: {:variant_literal, identifier}
  def function_type(from, to), do: {:function_type, from, to}
  def record_type(fields), do: {:record_type, fields}
  def variant_declaration(identifier, carries), do: {:variant_declaration, identifier, carries}
  def type_definition(generics, variants), do: {:type_definition, generics, variants}
  def type_annotation(expression, type), do: {:type_annotation, expression, type}
end
