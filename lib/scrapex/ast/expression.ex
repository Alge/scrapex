defmodule Scrapex.AST.Expression do
  alias Scrapex.AST.{Pattern, Literal, Identifier, Type}

  # Expression types
  @type group_expression :: {:group_expression, expression :: t()}
  @type unary_expression :: {:unary_expression, operator :: String.t(), expression :: t()}

  @type pattern_clause :: {pattern :: Pattern.t(), expression :: t()}

  @type pattern_match_expression ::
          {:pattern_match_expression, clauses :: [pattern_clause()]}

  # Record fields
  @type identifier_record_field ::
          {:identifier_record_field, identifier :: Identifier.t(), expression :: t()}
  @type anonymous_record_field :: {:anonymous_record_field, expression :: t()}
  @type record_field :: identifier_record_field() | anonymous_record_field()
  @type record_expression :: {:record_expression, fields :: [record_field()]}

  # Other expressions
  @type variant_construction ::
          {:variant_construction, id1 :: Identifier.t(), id2 :: Identifier.t(),
           arguments :: [prefix_expression()]}
  @type list_literal :: {:list_literal, elements :: [t()]}
  @type function_application ::
          {:function_application, function :: prefix_expression(),
           arguments :: [prefix_expression()]}

  # Prefix expressions
  @type prefix_expression ::
          Identifier.t()
          | unary_expression()
          | group_expression()
          | Literal.t()
          | pattern_match_expression()
          | record_expression()
          | variant_construction()
          | list_literal()
          | function_application()
          | Type.variant_literal()

  # Infix operations
  @type infix_operation :: {:infix_operation, operator :: atom(), expression :: t()}

  # Main expression type
  @type t ::
          {:expression, prefix :: prefix_expression(), infix :: infix_operation()}
          | Type.type_annotation()

  # =============================================================================
  # CONSTRUCTORS
  # =============================================================================

  def group_expression(expr), do: {:group_expression, expr}
  def unary_expression(op, expr), do: {:unary_expression, op, expr}
  def pattern_match_expression(clauses), do: {:pattern_match_expression, clauses}
  def identifier_record_field(id, expr), do: {:identifier_record_field, id, expr}
  def anonymous_record_field(expr), do: {:anonymous_record_field, expr}
  def record_expression(fields), do: {:record_expression, fields}
  def variant_construction(id1, id2, arguments), do: {:variant_construction, id1, id2, arguments}
  def list_literal(elements), do: {:list_literal, elements}
  def function_application(func, args), do: {:function_application, func, args}
  def infix_operation(op, expr), do: {:infix_operation, op, expr}
  def expression(prefix, infix), do: {:expression, prefix, infix}
end
