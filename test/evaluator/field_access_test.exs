# test/evaluator/field_access_test.exs

defmodule Scrapex.Evaluator.FieldAccessTest do
  use ExUnit.Case
  alias Scrapex.{Evaluator, AST, Value, Evaluator.Scope}

  describe "field access evaluation" do
    test "access field on simple record" do
      # {name = "John"}.name
      record_ast =
        AST.record_literal([
          AST.record_expression_field("name", AST.text("John"))
        ])

      ast_node = AST.field_access(record_ast, "name")
      scope = Scope.empty()

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("John")}
    end

    test "access field on record with multiple fields" do
      # {name = "John", age = 25}.age
      record_ast =
        AST.record_literal([
          AST.record_expression_field("name", AST.text("John")),
          AST.record_expression_field("age", AST.integer(25))
        ])

      ast_node = AST.field_access(record_ast, "age")
      scope = Scope.empty()

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(25)}
    end

    test "access field on record stored in variable" do
      # user.name where user = {name = "Alice", age = 30}
      ast_node = AST.field_access(AST.identifier("user"), "name")

      record_value =
        Value.record([
          {"name", Value.text("Alice")},
          {"age", Value.integer(30)}
        ])

      scope = Scope.empty() |> Scope.bind("user", record_value)

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("Alice")}
    end

    test "error when accessing field on non-record" do
      # "hello".name
      ast_node = AST.field_access(AST.text("hello"), "name")
      scope = Scope.empty()

      result = Evaluator.eval(ast_node, scope)

      assert {:error, reason} = result
      assert reason =~ "Cannot access field on non-record"
    end

    test "error when accessing non-existent field" do
      # {name = "John"}.age
      record_ast =
        AST.record_literal([
          AST.record_expression_field("name", AST.text("John"))
        ])

      ast_node = AST.field_access(record_ast, "age")
      scope = Scope.empty()

      result = Evaluator.eval(ast_node, scope)

      assert {:error, reason} = result
      assert reason =~ "Field 'age' not found in record"
    end

    test "chained field access" do
      # {user = {name = "Bob"}}.user.name
      inner_record =
        AST.record_literal([
          AST.record_expression_field("name", AST.text("Bob"))
        ])

      outer_record =
        AST.record_literal([
          AST.record_expression_field("user", inner_record)
        ])

      # Chain: first access .user, then .name
      first_access = AST.field_access(outer_record, "user")
      ast_node = AST.field_access(first_access, "name")
      scope = Scope.empty()

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("Bob")}
    end

    test "field access on computed record expression" do
      # (1 + 1; {name = "computed"}).name using where clause
      record_ast =
        AST.record_literal([
          AST.record_expression_field("name", AST.text("computed"))
        ])

      where_ast = AST.where(record_ast, AST.binding("dummy", AST.integer(1)))
      ast_node = AST.field_access(where_ast, "name")
      scope = Scope.empty()

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("computed")}
    end

    test "field access in arithmetic expression" do
      # {x = 5}.x + {y = 3}.y
      record1 = AST.record_literal([AST.record_expression_field("x", AST.integer(5))])
      record2 = AST.record_literal([AST.record_expression_field("y", AST.integer(3))])

      access1 = AST.field_access(record1, "x")
      access2 = AST.field_access(record2, "y")

      ast_node = AST.binary_op(access1, :plus, access2)
      scope = Scope.empty()

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(8)}
    end
  end
end
