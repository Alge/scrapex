defmodule Scrapex.Parser do
  alias Scrapex.{Token, AST}

  def parse_program([]) do
    {:error, "Empty input"}
  end

  def parse_program([%Token{type: :eof}]) do
    {:error, "Empty input"}
  end

  def parse_program(token_list) when is_list(token_list) do
    parse_program(token_list, [])
  end

  def parse_program(token_list, expressions) when is_list(token_list) when is_list(expressions) do
    case token_list do
      [%Token{type: :semicolon} | rest] ->
        parse_program(rest, expressions)

      [%Token{type: :eof} | _] ->
        expressions = expressions |> Enum.reverse()
        program_node = AST.program(expressions)
        {:ok, program_node}

      _ ->
        case parse_expression(token_list) do
          {:ok, expression_ast, rest} ->
            parse_program(rest, [expression_ast | expressions])

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  def parse_expression([%Token{type: :integer, value: value} | rest]) do
    {:ok, AST.integer(value), rest}
  end

  def parse_expression([%Token{type: :float, value: value} | rest]) do
    {:ok, AST.float(value), rest}
  end

  def parse_expression([%Token{type: :identifier, value: value} | rest]) do
    {:ok, AST.identifier(value), rest}
  end

  def parse_expression([%Token{type: :hexbyte, value: value} | rest]) do
    {:ok, AST.hexbyte(value), rest}
  end

  def parse_expression([%Token{type: :base64, value: value} | rest]) do
    {:ok, AST.base64(value), rest}
  end

  def parse_expression([%Token{type: :text, value: value} | rest]) do
    {:ok, AST.text(value), rest}
  end

  def parse_expression([%Token{type: :interpolated_text, value: value} | rest]) do
    {:ok, AST.interpolated_text(value), rest}
  end

  def parse_expression([%Token{type: :hole} | rest]) do
    {:ok, AST.hole(), rest}
  end

  def parse_expression([%Token{type: type, value: value}]) do
    {:error, "Don't know how to parse token of type: '#{type}', value: '#{value}'"}
  end
end
