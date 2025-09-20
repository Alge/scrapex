# lib/scrapex/ast.ex

defmodule Scrapex.AST do
  @moduledoc """
  Abstract Syntax Tree for ScrapScript.

  This module provides the main interface for creating and working with AST nodes.
  The actual implementations are in focused submodules.
  """

  alias Scrapex.AST.{Literal, Pattern, Identifier, Expression, Type, Record, Binding}

  # =============================================================================
  # TOP-LEVEL TYPES
  # =============================================================================

  @type astnode :: Literal.t() | Pattern.t() | Identifier.t() | Expression.t()

  # =============================================================================
  # DELEGATED FUNCTIONS
  # =============================================================================

  # === LITERAL CONSTRUCTORS ===
  defdelegate integer(value), to: Literal
  defdelegate float(value), to: Literal
  defdelegate text(value), to: Literal
  defdelegate interpolated_text(value), to: Literal
  defdelegate hexbyte(value), to: Literal
  defdelegate base64(value), to: Literal
  defdelegate hole(), to: Literal
  defdelegate literal?(token_type), to: Literal

  # === IDENTIFIER CONSTRUCTOR ===
  defdelegate identifier(name), to: Identifier, as: :new

  # === PATTERN CONSTRUCTORS ===
  defdelegate wildcard(), to: Pattern
  defdelegate empty_list(), to: Pattern
  defdelegate regular_list_pattern(elements), to: Pattern
  defdelegate concat_list_pattern(elements, tail), to: Pattern
  defdelegate cons_list_pattern(head, tail), to: Pattern

  defdelegate variant_pattern(identifier, patterns), to: Pattern
  defdelegate text_pattern(text, pattern), to: Pattern

  # === TYPE CONSTRUCTORS ===
  defdelegate variant(name), to: Type
  defdelegate variant(name, payload), to: Type
  defdelegate type_union(variants), to: Type
  defdelegate variant_literal(identifier), to: Type
  defdelegate function_type(from, to), to: Type
  defdelegate record_type(fields), to: Type
  defdelegate type_annotation(expression, type), to: Type

  # === EXPRESSION CONSTRUCTORS ===
  defdelegate unary_op(operator, operand), to: Expression
  defdelegate binary_op(left, operator, right), to: Expression

  defdelegate group_expression(expression), to: Expression
  defdelegate list_literal(elements), to: Expression
  defdelegate pattern_clause(pattern, expression), to: Expression
  defdelegate pattern_match_expression(clauses), to: Expression
  defdelegate function_app(identifier, argumente), to: Expression
  defdelegate type_declaration(name, variants), to: Expression
  defdelegate field_access(source, field), to: Expression
  defdelegate variant_constructor(type, variant), to: Expression
  defdelegate where(body, bindings), to: Expression

  # === RECORD CONSTRUCTORS ===
  defdelegate record_literal(fields), to: Record
  defdelegate record_pattern(fields), to: Record
  defdelegate spread_expression(expression), to: Record
  defdelegate record_rest(pattern), to: Record
  defdelegate record_expression_field(key, expression), to: Record
  defdelegate record_pattern_field(key, pattern), to: Record

  # === BINDING CONSTRUCTORS ===
  defdelegate binding(name, value_expr), to: Binding

  # =============================================================================
  # CONVENIENCE FUNCTIONS
  # =============================================================================

  @doc "Create a simple list pattern from elements"
  def list(elements), do: Pattern.regular_list_pattern(elements)
end
