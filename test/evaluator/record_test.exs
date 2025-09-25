defmodule Scrapex.Evaluator.RecordTest do
  use ExUnit.Case
  alias Scrapex.{Evaluator, AST, Value, Evaluator.Scope}

  describe "record literal evaluation" do
    test "evaluates empty record literal" do
      ast_node = AST.record_literal([])
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.record([])}
    end

    test "evaluates record with one field" do
      ast_node =
        AST.record_literal([
          AST.record_expression_field("name", AST.text("Alice"))
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected = Value.record([{"name", Value.text("Alice")}])
      assert result == {:ok, expected}
    end

    test "evaluates record with multiple fields" do
      ast_node =
        AST.record_literal([
          AST.record_expression_field("name", AST.text("Bob")),
          AST.record_expression_field("age", AST.integer(25)),
          AST.record_expression_field("active", AST.variant("true"))
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.record([
          {"name", Value.text("Bob")},
          {"age", Value.integer(25)},
          {"active", Value.variant("true")}
        ])

      assert result == {:ok, expected}
    end

    test "evaluates record with expressions as field values" do
      ast_node =
        AST.record_literal([
          AST.record_expression_field(
            "x",
            AST.binary_op(AST.integer(1), :plus, AST.integer(2))
          ),
          AST.record_expression_field(
            "y",
            AST.binary_op(AST.integer(3), :multiply, AST.integer(4))
          )
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.record([
          {"x", Value.integer(3)},
          {"y", Value.integer(12)}
        ])

      assert result == {:ok, expected}
    end

    test "evaluates record with variables from scope" do
      ast_node =
        AST.record_literal([
          AST.record_expression_field("name", AST.identifier("username")),
          AST.record_expression_field("count", AST.identifier("total"))
        ])

      scope =
        Scope.empty()
        |> Scope.bind("username", Value.text("admin"))
        |> Scope.bind("total", Value.integer(42))

      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.record([
          {"name", Value.text("admin")},
          {"count", Value.integer(42)}
        ])

      assert result == {:ok, expected}
    end

    test "returns error when field value evaluation fails" do
      ast_node =
        AST.record_literal([
          AST.record_expression_field("name", AST.identifier("undefined_var"))
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:error, "Undefined variable: 'undefined_var'"}
    end

    test "evaluates nested record literals" do
      inner_record =
        AST.record_literal([
          AST.record_expression_field("name", AST.text("Alice")),
          AST.record_expression_field("age", AST.integer(30))
        ])

      ast_node =
        AST.record_literal([
          AST.record_expression_field("person", inner_record),
          AST.record_expression_field("active", AST.variant("true"))
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.record([
          {"person",
           Value.record([
             {"name", Value.text("Alice")},
             {"age", Value.integer(30)}
           ])},
          {"active", Value.variant("true")}
        ])

      assert result == {:ok, expected}
    end
  end

  describe "record spread expressions" do
    test "evaluates record with spread expression" do
      ast_node =
        AST.record_literal([
          AST.spread_expression("base"),
          AST.record_expression_field("active", AST.variant("false"))
        ])

      base_record =
        Value.record([
          {"name", Value.text("Charlie")},
          {"age", Value.integer(35)}
        ])

      scope = Scope.empty() |> Scope.bind("base", base_record)
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.record([
          {"name", Value.text("Charlie")},
          {"age", Value.integer(35)},
          {"active", Value.variant("false")}
        ])

      assert result == {:ok, expected}
    end

    test "spread expression overrides existing fields" do
      ast_node =
        AST.record_literal([
          AST.record_expression_field("name", AST.text("Original")),
          AST.spread_expression("override")
        ])

      override_record = Value.record([{"name", Value.text("Overridden")}])
      scope = Scope.empty() |> Scope.bind("override", override_record)
      result = Evaluator.eval(ast_node, scope)

      expected = Value.record([{"name", Value.text("Overridden")}])
      assert result == {:ok, expected}
    end

    test "returns error when spread variable is undefined" do
      ast_node =
        AST.record_literal([
          AST.spread_expression("undefined_record")
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:error, "Undefined variable: 'undefined_record'"}
    end

    test "returns error when spread variable is not a record" do
      ast_node =
        AST.record_literal([
          AST.spread_expression("not_a_record")
        ])

      scope = Scope.empty() |> Scope.bind("not_a_record", Value.integer(42))
      result = Evaluator.eval(ast_node, scope)

      assert {:error, message} = result
      assert String.contains?(message, "Cannot spread")
    end
  end

  describe "records in where clauses" do
    test "evaluates record in where clause context" do
      ast_node =
        AST.where(
          AST.identifier("user"),
          AST.where(
            AST.binding(
              "user",
              AST.record_literal([
                AST.record_expression_field("name", AST.identifier("username")),
                AST.record_expression_field("id", AST.identifier("user_id"))
              ])
            ),
            AST.where(
              AST.binding("username", AST.text("admin")),
              AST.binding("user_id", AST.integer(123))
            )
          )
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.record([
          {"name", Value.text("admin")},
          {"id", Value.integer(123)}
        ])

      assert result == {:ok, expected}
    end
  end
end
