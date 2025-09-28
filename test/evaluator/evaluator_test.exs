defmodule Scrapex.EvaluatorTest do
  use ExUnit.Case
  alias Scrapex.{Evaluator, AST, Value, Evaluator.Scope}

  describe "Literals and Variables" do
    test "evaluates variant literal" do
      ast_node = AST.variant("true")
      result = Evaluator.eval(ast_node)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates integer literal" do
      # Create an integer AST node
      ast_node = AST.integer(42)

      # Evaluate the AST node
      result = Evaluator.eval(ast_node)

      # Should return tagged integer value
      assert result == {:ok, Value.integer(42)}
    end

    test "evaluates float literal" do
      ast_node = AST.float(3.14)
      result = Evaluator.eval(ast_node)

      assert result == {:ok, Value.float(3.14)}
    end

    test "evaluates text literal" do
      ast_node = AST.text("hello")
      result = Evaluator.eval(ast_node)

      assert result == {:ok, Value.text("hello")}
    end

    test "returns error for unimplemented AST nodes" do
      # Use an AST node we haven't implemented yet
      unimplemented_node = {:some_future_feature, "test"}
      result = Evaluator.eval(unimplemented_node)

      assert {:error, "Unimplemented AST node: " <> _} = result
    end

    test "looks up variable from scope" do
      # Create identifier AST node
      ast_node = AST.identifier("x")

      # Create scope with variable binding
      scope =
        Scope.empty()
        |> Scope.bind("x", Value.integer(42))

      result = Evaluator.eval(ast_node, scope)

      # Should return the value from scope
      assert result == {:ok, Value.integer(42)}
    end

    test "returns error for undefined variable" do
      # Create identifier AST node for undefined variable
      ast_node = AST.identifier("undefined_var")

      # Use empty scope
      scope = Scope.empty()

      result = Evaluator.eval(ast_node, scope)

      # Should return error
      assert result == {:error, "Undefined variable: 'undefined_var'"}
    end

    test "looks up variable from parent scope" do
      # Test scope chain traversal
      ast_node = AST.identifier("x")

      # Create nested scopes
      scope =
        Scope.empty()
        # Parent scope
        |> Scope.bind("x", Value.integer(100))
        # Child scope
        |> Scope.bind("y", Value.integer(200))

      result = Evaluator.eval(ast_node, scope)

      # Should find x in parent scope
      assert result == {:ok, Value.integer(100)}
    end

    test "evaluates hole literal" do
      ast_node = AST.hole()
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.hole()}
    end

    test "evaluates hole in where clause" do
      # result ; result = ()
      ast_node =
        AST.where(
          AST.identifier("result"),
          AST.binding("result", AST.hole())
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.hole()}
    end

    test "evaluates hole in list" do
      # [1, (), 3]
      ast_node =
        AST.list_literal([
          AST.integer(1),
          AST.hole(),
          AST.integer(3)
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          Value.integer(1),
          Value.hole(),
          Value.integer(3)
        ])

      assert result == {:ok, expected}
    end

    test "evaluates hole in record" do
      # {missing: (), present: 42}
      ast_node =
        AST.record_literal([
          {:expression_field, "missing", AST.hole()},
          {:expression_field, "present", AST.integer(42)}
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.record([
          {"missing", Value.hole()},
          {"present", Value.integer(42)}
        ])

      assert result == {:ok, expected}
    end

    test "evaluates hexbyte literal" do
      ast_node = AST.hexbyte(255)
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.hexbyte(255)}
    end

    test "evaluates hexbyte from hex string" do
      ast_node = AST.hexbyte("FF")
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.hexbyte(255)}
    end

    test "evaluates hexbyte in where clause" do
      # result ; result = ~A0
      ast_node =
        AST.where(
          AST.identifier("result"),
          AST.binding("result", AST.hexbyte(160))
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.hexbyte(160)}
    end

    test "evaluates hexbyte in list" do
      # [~00, ~FF, ~80]
      ast_node =
        AST.list_literal([
          AST.hexbyte(0),
          AST.hexbyte(255),
          AST.hexbyte(128)
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          Value.hexbyte(0),
          Value.hexbyte(255),
          Value.hexbyte(128)
        ])

      assert result == {:ok, expected}
    end

    test "evaluates hexbyte in record" do
      # {data: ~FF, checksum: ~A0}
      ast_node =
        AST.record_literal([
          {:expression_field, "data", AST.hexbyte(255)},
          {:expression_field, "checksum", AST.hexbyte(160)}
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.record([
          {"data", Value.hexbyte(255)},
          {"checksum", Value.hexbyte(160)}
        ])

      assert result == {:ok, expected}
    end

    test "evaluates hexbyte comparison operations" do
      # ~80 < ~FF
      ast_node = AST.binary_op(AST.hexbyte(128), :less_than, AST.hexbyte(255))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates hexbyte equality" do
      # ~FF == ~FF
      ast_node = AST.binary_op(AST.hexbyte(255), :double_equals, AST.hexbyte(255))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates hexbyte with variables" do
      # byte_val ; byte_val = ~FF
      ast_node =
        AST.where(
          AST.identifier("byte_val"),
          AST.binding("byte_val", AST.hexbyte("FF"))
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.hexbyte(255)}
    end

    test "evaluates base64 literal" do
      ast_node = AST.base64("SGVsbG8=")
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.base64("SGVsbG8=")}
    end

    test "evaluates base64 in where clause" do
      # result ; result = ~~AQIDBA==
      ast_node =
        AST.where(
          AST.identifier("result"),
          AST.binding("result", AST.base64("AQIDBA=="))
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.base64("AQIDBA==")}
    end

    test "evaluates base64 in list" do
      # [~~SGVsbG8=, ~~QQ==, ~~YWJjZA==]
      ast_node =
        AST.list_literal([
          AST.base64("SGVsbG8="),
          AST.base64("QQ=="),
          AST.base64("YWJjZA==")
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          Value.base64("SGVsbG8="),
          Value.base64("QQ=="),
          Value.base64("YWJjZA==")
        ])

      assert result == {:ok, expected}
    end

    test "evaluates base64 in record" do
      # {data: ~~SGVsbG8=, checksum: ~~AQIDBA==}
      ast_node =
        AST.record_literal([
          {:expression_field, "data", AST.base64("SGVsbG8=")},
          {:expression_field, "checksum", AST.base64("AQIDBA==")}
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.record([
          {"data", Value.base64("SGVsbG8=")},
          {"checksum", Value.base64("AQIDBA==")}
        ])

      assert result == {:ok, expected}
    end

    test "evaluates base64 equality" do
      # ~~SGVsbG8= == ~~SGVsbG8=
      ast_node = AST.binary_op(AST.base64("SGVsbG8="), :double_equals, AST.base64("SGVsbG8="))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates base64 inequality" do
      # ~~SGVsbG8= != ~~AQIDBA==
      ast_node = AST.binary_op(AST.base64("SGVsbG8="), :not_equals, AST.base64("AQIDBA=="))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates base64 with variables" do
      # encoded_data ; encoded_data = ~~SGVsbG8=
      ast_node =
        AST.where(
          AST.identifier("encoded_data"),
          AST.binding("encoded_data", AST.base64("SGVsbG8="))
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.base64("SGVsbG8=")}
    end

    test "evaluates mixed base64 and other types" do
      # [~~SGVsbG8=, "hello", 42]
      ast_node =
        AST.list_literal([
          AST.base64("SGVsbG8="),
          AST.text("hello"),
          AST.integer(42)
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          Value.base64("SGVsbG8="),
          Value.text("hello"),
          Value.integer(42)
        ])

      assert result == {:ok, expected}
    end
  end

  describe "interpolated text evaluation" do
    test "evaluates simple interpolated text with variable" do
      # "hello ` name ` world" where name = "Alice"
      ast_node =
        AST.interpolated_text([
          "hello ",
          AST.identifier("name"),
          " world"
        ])

      scope = Scope.empty() |> Scope.bind("name", Value.text("Alice"))
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("hello Alice world")}
    end

    test "evaluates interpolated text with text concatenation" do
      # "greeting: ` prefix ++ suffix `" where prefix = "Good", suffix = " morning"
      ast_node =
        AST.interpolated_text([
          "greeting: ",
          AST.binary_op(AST.identifier("prefix"), :double_plus, AST.identifier("suffix")),
          ""
        ])

      scope =
        Scope.empty()
        |> Scope.bind("prefix", Value.text("Good"))
        |> Scope.bind("suffix", Value.text(" morning"))

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("greeting: Good morning")}
    end

    test "evaluates interpolated text with multiple text expressions" do
      # "user: ` first_name `, last: ` last_name `"
      ast_node =
        AST.interpolated_text([
          "user: ",
          AST.identifier("first_name"),
          ", last: ",
          AST.identifier("last_name"),
          ""
        ])

      scope =
        Scope.empty()
        |> Scope.bind("first_name", Value.text("John"))
        |> Scope.bind("last_name", Value.text("Doe"))

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("user: John, last: Doe")}
    end

    test "evaluates nested interpolated text" do
      # "outer ` "inner ` x ` text" ` end" where x = "42"
      inner_interpolation =
        AST.interpolated_text([
          "inner ",
          AST.identifier("x"),
          " text"
        ])

      ast_node =
        AST.interpolated_text([
          "outer ",
          inner_interpolation,
          " end"
        ])

      scope = Scope.empty() |> Scope.bind("x", Value.text("42"))
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("outer inner 42 text end")}
    end

    test "evaluates interpolated text with complex nested expressions" do
      # "result: ` "score: ` points ++ " total" ` done"
      inner_interpolation =
        AST.interpolated_text([
          "score: ",
          AST.binary_op(AST.identifier("points"), :double_plus, AST.text(" total")),
          ""
        ])

      ast_node =
        AST.interpolated_text([
          "result: ",
          inner_interpolation,
          " done"
        ])

      scope = Scope.empty() |> Scope.bind("points", Value.text("95"))

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("result: score: 95 total done")}
    end

    test "evaluates interpolated text with record field access returning text" do
      # "user: ` person.name `"
      ast_node =
        AST.interpolated_text([
          "user: ",
          AST.field_access(AST.identifier("person"), "name"),
          ""
        ])

      person_record = Value.record([{"name", Value.text("Charlie")}])
      scope = Scope.empty() |> Scope.bind("person", person_record)
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("user: Charlie")}
    end

    test "evaluates interpolated text with text literals" do
      # "message: ` "Hello there" `"
      ast_node =
        AST.interpolated_text([
          "message: ",
          AST.text("Hello there"),
          ""
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("message: Hello there")}
    end

    test "evaluates empty interpolated text" do
      # Just text segments, no expressions
      ast_node = AST.interpolated_text(["hello world"])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("hello world")}
    end

    test "evaluates interpolated text with only text expressions" do
      # "` greeting `` target `" (no literal text between)
      ast_node =
        AST.interpolated_text([
          "",
          AST.identifier("greeting"),
          "",
          AST.identifier("target"),
          ""
        ])

      scope =
        Scope.empty()
        |> Scope.bind("greeting", Value.text("hello"))
        |> Scope.bind("target", Value.text("world"))

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("helloworld")}
    end

    test "evaluates interpolated text with empty text variables" do
      # "before ` empty_text ` after"
      ast_node =
        AST.interpolated_text([
          "before ",
          AST.identifier("empty_text"),
          " after"
        ])

      scope = Scope.empty() |> Scope.bind("empty_text", Value.text(""))
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("before  after")}
    end

    test "returns error when expression evaluation fails" do
      # "value: ` undefined_var `"
      ast_node =
        AST.interpolated_text([
          "value: ",
          AST.identifier("undefined_var"),
          ""
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Undefined variable: 'undefined_var'"} = result
    end

    test "returns error when nested expression fails" do
      # "outer ` "inner ` bad_var ` text" ` end"
      inner_interpolation =
        AST.interpolated_text([
          "inner ",
          AST.identifier("bad_var"),
          " text"
        ])

      ast_node =
        AST.interpolated_text([
          "outer ",
          inner_interpolation,
          " end"
        ])

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Undefined variable: 'bad_var'"} = result
    end

    test "returns error when interpolated expression is not text" do
      # "value: ` number `" where number is an integer (should fail)
      ast_node =
        AST.interpolated_text([
          "value: ",
          AST.identifier("number"),
          ""
        ])

      scope = Scope.empty() |> Scope.bind("number", Value.integer(42))
      result = Evaluator.eval(ast_node, scope)

      # This should fail because integers cannot be interpolated
      assert {:error, _reason} = result
    end

    test "evaluates interpolated text in where clause" do
      # result ; result = "hello ` name `"
      interpolated =
        AST.interpolated_text([
          "hello ",
          AST.identifier("name"),
          ""
        ])

      ast_node =
        AST.where(
          AST.identifier("result"),
          AST.binding("result", interpolated)
        )

      scope = Scope.empty() |> Scope.bind("name", Value.text("world"))
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("hello world")}
    end
  end

  describe "pipe operator evaluation" do
    test "evaluates simple pipe operation" do
      # 5 |> double where double = x -> x * 2
      ast_node = AST.binary_op(AST.integer(5), :pipe_operator, AST.identifier("double"))

      double_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :multiply, AST.integer(2))
          )
        ])

      double_func = Value.function(double_pattern, Scope.empty())

      scope = Scope.empty() |> Scope.bind("double", double_func)
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(10)}
    end

    test "evaluates chained pipe operations" do
      # 5 |> double |> add_one
      inner_pipe = AST.binary_op(AST.integer(5), :pipe_operator, AST.identifier("double"))
      ast_node = AST.binary_op(inner_pipe, :pipe_operator, AST.identifier("add_one"))

      double_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :multiply, AST.integer(2))
          )
        ])

      add_one_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :plus, AST.integer(1))
          )
        ])

      scope =
        Scope.empty()
        |> Scope.bind("double", Value.function(double_pattern, Scope.empty()))
        |> Scope.bind("add_one", Value.function(add_one_pattern, Scope.empty()))

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(11)}
    end

    test "evaluates pipe with text values" do
      # "hello" |> uppercase where uppercase = s -> s ++ "!"
      ast_node = AST.binary_op(AST.text("hello"), :pipe_operator, AST.identifier("exclaim"))

      exclaim_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("s"),
            AST.binary_op(AST.identifier("s"), :double_plus, AST.text("!"))
          )
        ])

      exclaim_func = Value.function(exclaim_pattern, Scope.empty())

      scope = Scope.empty() |> Scope.bind("exclaim", exclaim_func)
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("hello!")}
    end

    test "evaluates pipe with list values" do
      # [1, 2] |> head where head extracts first element
      ast_node =
        AST.binary_op(
          AST.list_literal([AST.integer(1), AST.integer(2)]),
          :pipe_operator,
          AST.identifier("head")
        )

      head_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.cons_list_pattern(AST.identifier("h"), AST.identifier("_")),
            AST.identifier("h")
          )
        ])

      head_func = Value.function(head_pattern, Scope.empty())

      scope = Scope.empty() |> Scope.bind("head", head_func)
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(1)}
    end

    test "evaluates pipe with record values" do
      # {name: "Alice"} |> get_name where get_name = r -> r.name
      record_ast =
        AST.record_literal([
          {:expression_field, "name", AST.text("Alice")}
        ])

      ast_node = AST.binary_op(record_ast, :pipe_operator, AST.identifier("get_name"))

      get_name_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("r"),
            AST.field_access(AST.identifier("r"), "name")
          )
        ])

      get_name_func = Value.function(get_name_pattern, Scope.empty())

      scope = Scope.empty() |> Scope.bind("get_name", get_name_func)
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("Alice")}
    end

    test "evaluates pipe with variables" do
      # x |> f where x = 10, f = n -> n - 5
      ast_node = AST.binary_op(AST.identifier("x"), :pipe_operator, AST.identifier("f"))

      subtract_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("n"),
            AST.binary_op(AST.identifier("n"), :minus, AST.integer(5))
          )
        ])

      scope =
        Scope.empty()
        |> Scope.bind("x", Value.integer(10))
        |> Scope.bind("f", Value.function(subtract_pattern, Scope.empty()))

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(5)}
    end

    test "evaluates pipe in where clause" do
      # result ; result = 3 |> double
      pipe_expr = AST.binary_op(AST.integer(3), :pipe_operator, AST.identifier("double"))

      ast_node =
        AST.where(
          AST.identifier("result"),
          AST.binding("result", pipe_expr)
        )

      double_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :multiply, AST.integer(2))
          )
        ])

      scope = Scope.empty() |> Scope.bind("double", Value.function(double_pattern, Scope.empty()))
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(6)}
    end

    test "evaluates complex pipe chain with mixed operations" do
      # 2 |> double |> add_one |> double
      pipe1 = AST.binary_op(AST.integer(2), :pipe_operator, AST.identifier("double"))
      pipe2 = AST.binary_op(pipe1, :pipe_operator, AST.identifier("add_one"))
      ast_node = AST.binary_op(pipe2, :pipe_operator, AST.identifier("double"))

      double_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :multiply, AST.integer(2))
          )
        ])

      add_one_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :plus, AST.integer(1))
          )
        ])

      scope =
        Scope.empty()
        |> Scope.bind("double", Value.function(double_pattern, Scope.empty()))
        |> Scope.bind("add_one", Value.function(add_one_pattern, Scope.empty()))

      result = Evaluator.eval(ast_node, scope)

      # 2 |> double = 4, |> add_one = 5, |> double = 10
      assert result == {:ok, Value.integer(10)}
    end

    test "returns error when function is undefined" do
      # 5 |> undefined_func
      ast_node = AST.binary_op(AST.integer(5), :pipe_operator, AST.identifier("undefined_func"))

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Undefined variable: 'undefined_func'"} = result
    end

    test "returns error when left operand evaluation fails" do
      # undefined_var |> double
      ast_node =
        AST.binary_op(AST.identifier("undefined_var"), :pipe_operator, AST.identifier("double"))

      double_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(
            AST.identifier("x"),
            AST.binary_op(AST.identifier("x"), :multiply, AST.integer(2))
          )
        ])

      scope = Scope.empty() |> Scope.bind("double", Value.function(double_pattern, Scope.empty()))
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Undefined variable: 'undefined_var'"} = result
    end

    test "returns error when right operand is not a function" do
      # 5 |> 10 (should fail - 10 is not a function)
      ast_node = AST.binary_op(AST.integer(5), :pipe_operator, AST.integer(10))

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, _reason} = result
    end

    test "returns error when function pattern doesn't match" do
      # "hello" |> numeric_only where numeric_only only accepts integers
      ast_node = AST.binary_op(AST.text("hello"), :pipe_operator, AST.identifier("numeric_only"))

      numeric_pattern =
        AST.pattern_match_expression([
          AST.pattern_clause(AST.integer(42), AST.integer(1))
        ])

      numeric_func = Value.function(numeric_pattern, Scope.empty())

      scope = Scope.empty() |> Scope.bind("numeric_only", numeric_func)
      result = Evaluator.eval(ast_node, scope)

      assert {:error, _reason} = result
    end
  end

  describe "binary operations" do
    test "evaluates integer addition" do
      # 1 + 2
      ast_node = AST.binary_op(AST.integer(1), :plus, AST.integer(2))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(3)}
    end

    test "evaluates float addition" do
      # 1.5 + 2.3
      ast_node = AST.binary_op(AST.float(1.5), :plus, AST.float(2.3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.float(3.8)}
    end

    test "evaluates integer subtraction" do
      # 5 - 3
      ast_node = AST.binary_op(AST.integer(5), :minus, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(2)}
    end

    test "evaluates float subtraction" do
      # 5.7 - 3.2
      ast_node = AST.binary_op(AST.float(5.7), :minus, AST.float(3.2))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.float(2.5)}
    end

    test "evaluates integer multiplication" do
      # 4 * 3
      ast_node = AST.binary_op(AST.integer(4), :multiply, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(12)}
    end

    test "evaluates float multiplication" do
      # 4.0 * 3.5
      ast_node = AST.binary_op(AST.float(4.0), :multiply, AST.float(3.5))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.float(14.0)}
    end

    test "evaluates integer division" do
      # 6 / 2
      ast_node = AST.binary_op(AST.integer(6), :slash, AST.integer(2))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(3)}
    end

    test "evaluates float division" do
      # 9.0 / 3.0
      ast_node = AST.binary_op(AST.float(9.0), :slash, AST.float(3.0))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.float(3.0)}
    end

    test "evaluates text concatenation" do
      # "hello" ++ " world"
      ast_node = AST.binary_op(AST.text("hello"), :double_plus, AST.text(" world"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.text("hello world")}
    end

    test "evaluates binary operation with variables" do
      # x + y; x=10; y=20
      ast_node = AST.binary_op(AST.identifier("x"), :plus, AST.identifier("y"))

      scope =
        Scope.empty()
        |> Scope.bind("x", Value.integer(10))
        |> Scope.bind("y", Value.integer(20))

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(30)}
    end

    test "evaluates nested binary operations" do
      # (1 + 2) * 3
      inner = AST.binary_op(AST.integer(1), :plus, AST.integer(2))
      ast_node = AST.binary_op(inner, :multiply, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(9)}
    end

    test "returns error for type mismatch in binary operation" do
      # 1 + "hello" should fail
      ast_node = AST.binary_op(AST.integer(1), :plus, AST.text("hello"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error,
              "Operator '+' not supported between value '{:integer, 1}' and '{:text, \"hello\"}'"} =
               result
    end

    test "returns error for undefined variable in binary operation" do
      # x + 1 where x is undefined
      ast_node = AST.binary_op(AST.identifier("x"), :plus, AST.integer(1))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Undefined variable: 'x'"} = result
    end

    test "returns error for unimplemented binary operator" do
      # Test with an operator we haven't implemented
      ast_node = AST.binary_op(AST.integer(1), :some_future_op, AST.integer(2))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error,
              "Unimplemented AST node: {:binary_op, {:integer, 1}, :some_future_op, {:integer, 2}}"} =
               result
    end

    test "evaluates cons operation" do
      # 1 >+ [2, 3]
      list_ast = AST.list_literal([AST.integer(2), AST.integer(3)])
      ast_node = AST.binary_op(AST.integer(1), :cons, list_ast)
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected = Value.list([Value.integer(1), Value.integer(2), Value.integer(3)])
      assert result == {:ok, expected}
    end

    test "evaluates cons with variables" do
      # head >+ tail; head = 5; tail = [10, 15]
      ast_node = AST.binary_op(AST.identifier("head"), :cons, AST.identifier("tail"))

      scope =
        Scope.empty()
        |> Scope.bind("head", Value.integer(5))
        |> Scope.bind("tail", Value.list([Value.integer(10), Value.integer(15)]))

      result = Evaluator.eval(ast_node, scope)

      expected = Value.list([Value.integer(5), Value.integer(10), Value.integer(15)])
      assert result == {:ok, expected}
    end

    # TODO: type system not implemented yet!
    @tag :skip
    test "returns error for cons type mismatch" do
      # "hello" >+ [1, 2] should fail
      list_ast = AST.list_literal([AST.integer(1), AST.integer(2)])
      ast_node = AST.binary_op(AST.text("hello"), :cons, list_ast)
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, _reason} = result
    end

    test "evaluates append to list operation" do
      # [1, 2] +< 3
      list_ast = AST.list_literal([AST.integer(1), AST.integer(2)])
      ast_node = AST.binary_op(list_ast, :append, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected = Value.list([Value.integer(1), Value.integer(2), Value.integer(3)])
      assert result == {:ok, expected}
    end

    test "evaluates append to empty list" do
      # [] +< 42
      list_ast = AST.list_literal([])
      ast_node = AST.binary_op(list_ast, :append, AST.integer(42))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected = Value.list([Value.integer(42)])
      assert result == {:ok, expected}
    end

    test "evaluates append with text values" do
      # ["hello"] +< "world"
      list_ast = AST.list_literal([AST.text("hello")])
      ast_node = AST.binary_op(list_ast, :append, AST.text("world"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected = Value.list([Value.text("hello"), Value.text("world")])
      assert result == {:ok, expected}
    end

    test "evaluates append with variables" do
      # my_list +< item
      ast_node = AST.binary_op(AST.identifier("my_list"), :append, AST.identifier("item"))

      scope =
        Scope.empty()
        |> Scope.bind("my_list", Value.list([Value.integer(1), Value.integer(2)]))
        |> Scope.bind("item", Value.integer(3))

      result = Evaluator.eval(ast_node, scope)

      expected = Value.list([Value.integer(1), Value.integer(2), Value.integer(3)])
      assert result == {:ok, expected}
    end

    test "evaluates chained append operations" do
      # [1] +< 2 +< 3
      list_ast = AST.list_literal([AST.integer(1)])
      middle_ast = AST.binary_op(list_ast, :append, AST.integer(2))
      ast_node = AST.binary_op(middle_ast, :append, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected = Value.list([Value.integer(1), Value.integer(2), Value.integer(3)])
      assert result == {:ok, expected}
    end

    test "evaluates append with nested list" do
      # [1, 2] +< [3, 4]
      list1_ast = AST.list_literal([AST.integer(1), AST.integer(2)])
      list2_ast = AST.list_literal([AST.integer(3), AST.integer(4)])
      ast_node = AST.binary_op(list1_ast, :append, list2_ast)
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      expected =
        Value.list([
          Value.integer(1),
          Value.integer(2),
          Value.list([Value.integer(3), Value.integer(4)])
        ])

      assert result == {:ok, expected}
    end

    test "returns error for append to non-list" do
      # 42 +< 3 should fail
      ast_node = AST.binary_op(AST.integer(42), :append, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Cannot append to non-list"} = result
    end

    test "returns error for append when left operand is undefined" do
      # undefined_var +< 5
      ast_node = AST.binary_op(AST.identifier("undefined_var"), :append, AST.integer(5))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Undefined variable: 'undefined_var'"} = result
    end

    test "returns error for append when right operand is undefined" do
      # [1, 2] +< undefined_var
      list_ast = AST.list_literal([AST.integer(1), AST.integer(2)])
      ast_node = AST.binary_op(list_ast, :append, AST.identifier("undefined_var"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Undefined variable: 'undefined_var'"} = result
    end

    test "evaluates equality comparison" do
      # 5 == 5
      ast_node = AST.binary_op(AST.integer(5), :double_equals, AST.integer(5))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates inequality comparison" do
      # 3 != 7
      ast_node = AST.binary_op(AST.integer(3), :not_equals, AST.integer(7))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates less than comparison" do
      # 2 < 5
      ast_node = AST.binary_op(AST.integer(2), :less_than, AST.integer(5))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates greater than comparison" do
      # 8 > 3
      ast_node = AST.binary_op(AST.integer(8), :greater_than, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates false equality comparison" do
      # 5 == 7
      ast_node = AST.binary_op(AST.integer(5), :double_equals, AST.integer(7))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("false")}
    end

    test "evaluates false inequality comparison" do
      # 5 != 5
      ast_node = AST.binary_op(AST.integer(5), :not_equals, AST.integer(5))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("false")}
    end

    test "evaluates comparison with variables" do
      # x < y where x = 3, y = 7
      ast_node = AST.binary_op(AST.identifier("x"), :less_than, AST.identifier("y"))

      scope =
        Scope.empty()
        |> Scope.bind("x", Value.integer(3))
        |> Scope.bind("y", Value.integer(7))

      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates comparison with text values" do
      # "apple" < "banana"
      ast_node = AST.binary_op(AST.text("apple"), :less_than, AST.text("banana"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates comparison with float values" do
      # 3.14 > 2.71
      ast_node = AST.binary_op(AST.float(3.14), :greater_than, AST.float(2.71))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates comparison with variants" do
      # #ok == #ok
      ast_node = AST.binary_op(AST.variant("ok"), :double_equals, AST.variant("ok"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "evaluates chained comparisons" do
      # (1 < 2) == #true
      left_comparison = AST.binary_op(AST.integer(1), :less_than, AST.integer(2))
      ast_node = AST.binary_op(left_comparison, :double_equals, AST.variant("true"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end

    test "returns error for comparison type mismatch" do
      # 5 == "5" should fail
      ast_node = AST.binary_op(AST.integer(5), :double_equals, AST.text("5"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, _reason} = result
    end

    test "returns error for less than with variants" do
      # #ok < #error should fail
      ast_node = AST.binary_op(AST.variant("ok"), :less_than, AST.variant("error"))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, _reason} = result
    end

    test "returns error when comparison operand is undefined" do
      # x == 5 where x is undefined
      ast_node = AST.binary_op(AST.identifier("undefined_var"), :double_equals, AST.integer(5))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert {:error, "Undefined variable: 'undefined_var'"} = result
    end

    test "evaluates comparison in arithmetic context" do
      # 1 + 2 == 3
      left_expr = AST.binary_op(AST.integer(1), :plus, AST.integer(2))
      ast_node = AST.binary_op(left_expr, :double_equals, AST.integer(3))
      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.variant("true")}
    end
  end

  describe "where clauses" do
    test "evaluates simple where clause" do
      # x ; x = 42
      ast_node =
        AST.where(
          # body: x
          AST.identifier("x"),
          # binding: x = 42
          AST.binding("x", AST.integer(42))
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(42)}
    end

    test "evaluates where clause with dependency" do
      # y ; y = x + 5 ; x = 10
      ast_node =
        AST.where(
          # body: y
          AST.identifier("y"),
          AST.where(
            # binding: y = x + 5
            AST.binding(
              "y",
              AST.binary_op(
                AST.identifier("x"),
                :plus,
                AST.integer(5)
              )
            ),
            AST.binding("x", AST.integer(10))
          )
        )

      scope = Scope.empty()
      result = Evaluator.eval(ast_node, scope)

      assert result == {:ok, Value.integer(15)}
    end
  end
end
