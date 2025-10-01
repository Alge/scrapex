# lib/scrapex/pretty_printer.ex
defmodule Scrapex.PrettyPrinter do
  alias Scrapex.Evaluator.Scope
  alias Scrapex.Token

  @doc """
  A polymorphic pretty-printer for Scrapex data structures.

  It can format:
  - AST nodes (tuples)
  - Evaluator scopes (structs)
  - Token lists

  ## Examples

      iex> ast = {:where, {:integer, 1}, {:binding, "x", {:integer, 2}}}
      iex> PrettyPrinter.format(ast)
      "WHERE\\n· INT(1)\\n· BINDING(x)\\n· · INT(2)\\n"

      iex> tokens = [Token.new(:identifier, "x", 1, 1), Token.new(:equals, 1, 3)]
      iex> PrettyPrinter.format(tokens)
      "[1:1]  IDENTIFIER  \\"x\\"\\n[1:3]  EQUALS\\n"

  """

  # ==================================================================
  # PUBLIC API (The Dispatcher)
  # ==================================================================

  # Formats an evaluator scope
  def format(%Scope{} = scope) do
    # Kick off the scope-specific formatting.
    format_scope_chain(scope, 0)
    |> Enum.join("\n")
    |> (&(&1 <> "\n")).()
  end

  # Formats an AST node.
  def format(ast_node) when is_tuple(ast_node) do
    # Kick off the AST-specific formatting.
    format_ast_node(ast_node, "")
    |> Enum.join("\n")
    |> (&(&1 <> "\n")).()
  end

  # "Formats a list of tokens.
  def format(token_list) when is_list(token_list) do
    # This check ensures we only format lists of tokens, not other kinds of lists.
    if Enum.all?(token_list, &is_struct(&1, Token)) do
      format_token_list(token_list)
      |> Enum.join("\n")
      |> (&(&1 <> "\n")).()
    else
      # Fallback for generic lists
      inspect(token_list)
    end
  end

  # Handles any other data type as a fallback.
  def format(other) do
    inspect(other)
  end

  # ==================================================================
  # PRIVATE: Token List Formatting Logic
  # ==================================================================

  defp format_token_list([]), do: ["(empty token list)"]

  defp format_token_list(token_list) do
    # First, find the maximum width of the token type names for alignment.
    max_type_width =
      Enum.map(token_list, fn token ->
        token.type |> Atom.to_string() |> String.length()
      end)
      |> Enum.max()

    # Now, map over each token to create its formatted string.
    Enum.map(token_list, &format_one_token(&1, max_type_width))
  end

  defp format_one_token(token, type_width) do
    # Format the position part, e.g., "[1:5]"
    pos_str = "[#{token.line}:#{token.column}]"

    # Format the type part, upcased and padded for alignment.
    type_str =
      token.type
      |> Atom.to_string()
      |> String.upcase()
      |> String.pad_trailing(type_width)

    # Format the value part, but only if it exists.
    value_str = if token.value, do: "  #{inspect(token.value)}", else: ""

    # Combine the parts into a single line.
    "#{String.pad_trailing(pos_str, 8)} #{type_str}#{value_str}"
  end

  # ==================================================================
  # PRIVATE: Scope Formatting Logic
  # ==================================================================
  # (This section remains unchanged)

  defp format_scope_chain(nil, depth) do
    prefix = String.duplicate("· ", depth)
    ["#{prefix}Global Scope (end of chain)"]
  end

  defp format_scope_chain(scope, depth) do
    prefix = String.duplicate("· ", depth)
    child_prefix = prefix <> "· "

    header_line =
      if depth == 0, do: "#{prefix}Scope #{depth} (current):", else: "#{prefix}Scope #{depth}:"

    name_line = "#{child_prefix}name:  #{inspect(scope.name)}"

    value_lines =
      case scope.value do
        value when is_tuple(value) ->
          formatted_ast_lines = format_ast_node(value, child_prefix <> "· ")
          [first_ast_line | rest_ast_lines] = formatted_ast_lines
          ["#{child_prefix}value: #{first_ast_line}" | rest_ast_lines]

        value ->
          ["#{child_prefix}value: #{inspect(value)}"]
      end

    parent_lines = format_scope_chain(scope.parent, depth + 1)

    [header_line, name_line] ++ value_lines ++ parent_lines
  end

  # ==================================================================
  # PRIVATE: AST Formatting Logic
  # ==================================================================
  # (This section remains unchanged)

  defp format_ast_node(node, prefix) do
    {header, children} = get_node_parts(node)
    header_line = prefix <> header
    child_prefix = prefix <> "· "

    child_lines =
      for child_node <- children do
        format_ast_node(child_node, child_prefix)
      end
      |> List.flatten()

    [header_line | child_lines]
  end

  defp get_node_parts(node) do
    case node do
      {:integer, val} ->
        {"INT(#{val})", []}

      {:text, val} ->
        {"TEXT(#{inspect(val)})", []}

      {:identifier, name} ->
        {"IDENT(#{name})", []}

      {:wildcard} ->
        {"WILDCARD(_)", []}

      {:hole} ->
        {"HOLE", []}

      {:variant, name, {:hole}} ->
        {"VARIANT(##{name})", []}

      {:where, body, bindings} ->
        {"WHERE", [body, bindings]}

      {:binding, name, expr} ->
        {"BINDING(#{name})", [expr]}

      {:typed_binding, name, type, val} ->
        {"TYPED_BINDING(#{name})", [type, val]}

      {:binary_op, l, op, r} ->
        {"BINARY_OP(#{op})", [l, r]}

      {:function, name, body, _scope} ->
        {"FUNCTION(#{name})", [body]}

      {:function_app, fun, arg} ->
        {"FUNCTION_APP", [fun, arg]}

      {:pattern_match_expression, clauses} ->
        {"PATTERN_MATCH", clauses}

      {:pattern_clause, pat, body} ->
        {"CLAUSE", [pat, body]}

      {:variant, name, payload} ->
        {"VARIANT(##{name})", [payload]}

      {:variant_pattern, {:identifier, name_str}, payload_patterns} ->
        {"VARIANT_PATTERN(##{name_str})", payload_patterns}

      {:type_declaration, name, type_union} ->
        {"TYPE_DECL(#{name})", [type_union]}

      {:type_union, variants} ->
        {"TYPE_UNION", variants}

      {:variant_def, name, payload} ->
        {"VARIANT_DEF(##{name})", [payload]}

      {:generic_type_declaration, name, params, body} ->
        params_str =
          Enum.map(params, fn {:identifier, p_name} -> p_name end)
          |> Enum.join(", ")

        {"GENERIC_TYPE_DECL(#{name}<#{params_str}>)", [body]}

      other ->
        {"UNHANDLED_NODE(#{inspect(other)})", []}
    end
  end
end
