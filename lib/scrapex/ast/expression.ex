# lib/scrapex/ast/expression.ex

defmodule Scrapex.AST.Expression do
  @moduledoc """
  AST nodes for ScrapScript expressions.
  This module uses a traditional operator tree structure.
  """

  alias Scrapex.AST.{Literal, Identifier, Pattern, Type, Record, Binding}
  alias Scrapex.AST

  # =============================================================================
  # TYPESPECS
  # =============================================================================

  @typedoc "Represents a unary operation, e.g., -x"
  @type unary_op :: {:unary_op, operator :: atom(), operand :: t()}

  @typedoc "Represents a binary operation, e.g., a + b"
  @type binary_op :: {:binary_op, left :: t(), operator :: atom(), right :: t()}

  # --- These are other forms of complex expressions ---
  @typedoc "Represents a parenthesized expression from the source."
  @type group_expression :: {:group_expression, inner_expression :: t()}

  @typedoc "Represents a pattern matching block, e.g., | a -> 1 | b -> 2"
  @type pattern_clause :: {:pattern_clause, Pattern.t(), t()}
  @type pattern_match_expression :: {:pattern_match_expression, clauses :: [pattern_clause()]}

  @typedoc "Represents a list literal, e.g., [1, 2, 3]"
  @type list_literal :: {:list_literal, elements :: [t()]}

  @type function_app :: {:function_app, function :: t(), argument :: t()}
  @type type_declaration :: {:type_declaration, name :: String.t(), variants :: [Type.variant()]}

  @type field_access :: {:field_access, source :: t(), field :: Identifier.t()}

  @typedoc "Represents a constructed variant value, e.g., #ok 42 or #true"
  @type variant :: {:variant, tag :: String.t(), payload :: t()}

  @type where :: {:where, body :: t(), binding :: t()}

  @type function_expression ::
          {:function, pattern_match_expr :: pattern_match_expression(), closure :: Scope.t()}

  # function_application, etc., here in the same style.

  @typedoc "The main union type for any valid expression."
  # Simple, atomic expressions
  @type t ::
          Literal.t()
          | Identifier.t()
          | Type.variant_literal()
          # Structural expressions
          | unary_op()
          | binary_op()
          | group_expression()
          | list_literal()
          | Record.record_literal()
          | pattern_match_expression()
          # This represents a type annotation like `x : int`
          | Type.type_annotation()
          | function_app()
          | type_declaration()
          | field_access()
          | where()
          | Binding.t()
          | function_expression()
          | variant()

  # =============================================================================
  # CONSTRUCTORS
  # =============================================================================

  def unary_op(operator, operand), do: {:unary_op, operator, operand}
  def binary_op(left, operator, right), do: {:binary_op, left, operator, right}
  def group_expression(expression), do: {:group_expression, expression}
  def list_literal(elements), do: {:list_literal, elements}
  def pattern_clause(pattern, expression), do: {:pattern_clause, pattern, expression}
  def pattern_match_expression(clauses), do: {:pattern_match_expression, clauses}
  def function_app(identifier, argument), do: {:function_app, identifier, argument}
  def type_declaration(name, variants), do: {:type_declaration, name, variants}

  def field_access(source, field_name) when is_binary(field_name),
    do: {:field_access, source, field_name}

  def variant(tag, payload), do: {:variant, tag, payload}
  def variant(tag), do: {:variant, tag, AST.hole()}
  def where(body, binding), do: {:where, body, binding}
  def function_expression(patter_match_expr, closure), do: {:function, patter_match_expr, closure}
end
