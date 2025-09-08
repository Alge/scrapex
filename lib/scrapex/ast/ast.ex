# lib/scrapex/ast.ex

defmodule Scrapex.AST do
  @moduledoc """
  Abstract Syntax Tree for ScrapScript.

  This module provides the main interface for creating and working with AST nodes.
  The actual implementations are in focused submodules.
  """

  alias Scrapex.AST.{Literal, Pattern, Identifier, Expression, Program, Type}

  # =============================================================================
  # TOP-LEVEL TYPES
  # =============================================================================

  @type astnode :: Literal.t() | Pattern.t() | Identifier.t() | Expression.t() | Program.t()

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

  # === IDENTIFIER CONSTRUCTOR ===
  defdelegate identifier(name), to: Identifier, as: :new

  # === PATTERN CONSTRUCTORS ===
  defdelegate wildcard(), to: Pattern
  defdelegate empty_list(), to: Pattern
  defdelegate regular_list_pattern(elements), to: Pattern
  defdelegate concat_list_pattern(elements, tail), to: Pattern
  defdelegate cons_list_pattern(head, tail), to: Pattern
  defdelegate record_field(identifier, pattern), to: Pattern
  defdelegate record_rest(pattern), to: Pattern
  defdelegate record_pattern(fields), to: Pattern
  defdelegate variant_pattern(identifier, patterns), to: Pattern
  defdelegate text_pattern(text, pattern), to: Pattern

  # === TYPE CONSTRUCTORS ===
  defdelegate variant_literal(identifier), to: Type
  defdelegate function_type(from, to), to: Type
  defdelegate record_type(fields), to: Type
  defdelegate variant_declaration(identifier, carries), to: Type
  defdelegate type_definition(generics, variants), to: Type
  defdelegate type_annotation(expression, type), to: Type

  # === EXPRESSION CONSTRUCTORS ===
  defdelegate group_expression(expr), to: Expression
  defdelegate unary_expression(op, expr), to: Expression
  defdelegate pattern_match_expression(clauses), to: Expression
  defdelegate identifier_record_field(id, expr), to: Expression
  defdelegate anonymous_record_field(expr), to: Expression
  defdelegate record_expression(fields), to: Expression
  defdelegate variant_construction(id1, id2, arguments), to: Expression
  defdelegate list_literal(elements), to: Expression
  defdelegate function_application(func, args), to: Expression
  defdelegate infix_operation(op, expr), to: Expression
  defdelegate expression(prefix, infix), to: Expression

  # === PROGRAM CONSTRUCTOR ===
  defdelegate program(expressions), to: Program, as: :new

  # =============================================================================
  # CONVENIENCE FUNCTIONS
  # =============================================================================

  @doc "Create a simple list pattern from elements"
  def list(elements), do: Pattern.regular_list_pattern(elements)

  @doc "Create a record with field patterns"
  def record(fields), do: Pattern.record_pattern(fields)

  @doc "Convenience for creating record fields"
  def field(name, pattern) when is_binary(name) do
    Pattern.record_field(identifier(name), pattern)
  end

  @doc "Convenience for creating record rest patterns"
  def rest(pattern), do: Pattern.record_rest(pattern)

  @doc "Create a simple binary operation expression"
  def binary_op(left, op, right) do
    Expression.expression(left, Expression.infix_operation(op, right))
  end

  @doc "Create a simple function call"
  def call(func_name, args) when is_binary(func_name) do
    Expression.function_application(identifier(func_name), args)
  end
end
