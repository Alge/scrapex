# lib/scrapex/cli.ex

defmodule Scrapex.CLI do
  @moduledoc """
  Command line interface for the Scrapex toolkit.
  Provides commands to lex, parse, and evaluate ScrapScript.
  """

  alias Scrapex.{Lexer, Parser, Token}

  @doc """
  The main entry point for the command line application.
  Dispatches to the appropriate command handler.
  """
  def main(args) do
    case args do
      # --- COMMAND DISPATCHER ---
      ["lex" | rest_args] -> run_lex(rest_args)
      ["parse" | rest_args] -> run_parse(rest_args)
      ["eval" | _rest_args] -> run_eval()

      # --- GLOBAL OPTIONS ---
      ["--help"] -> print_help()
      ["-h"] -> print_help()
      [] -> print_help()

      # --- ERROR HANDLING ---
      [unknown | _] ->
        IO.puts(:stderr, "Error: Unknown command '#{unknown}'. Use --help for usage.")
        System.halt(1)
    end
  end

  # =============================================================================
  # COMMAND HANDLERS
  # =============================================================================

  defp run_lex(args) do
    handle_input(args, &lex_and_print/2)
  end

  defp run_parse(args) do
    handle_input(args, &parse_and_print/2)
  end

  defp run_eval do
    IO.puts("The 'eval' command is not yet implemented.")
  end

  # =============================================================================
  # CORE LOGIC
  # =============================================================================

  # A generic input handler that reads from a file or stdin, then
  # applies the given `action_fun` to the content.
  defp handle_input(args, action_fun) do
    case args do
      [] ->
        # Read from stdin
        content = IO.read(:stdio, :eof)
        action_fun.(content, "<stdin>")
      [filename] ->
        # Read from a file
        case File.read(filename) do
          {:ok, content} ->
            action_fun.(content, filename)
          {:error, reason} ->
            IO.puts(:stderr, "Error reading file '#{filename}': #{:file.format_error(reason)}")
            System.halt(1)
        end
      _ ->
        IO.puts(:stderr, "Error: Too many arguments for this command. Use --help for usage.")
        System.halt(1)
    end
  end

  # Action function for the 'lex' command.
  defp lex_and_print(input, source) do
    # --- THIS IS THE FIX ---
    # We check if the result is a list (success) or an error tuple.
    case Lexer.tokenize(input) do
      tokens when is_list(tokens) ->
        IO.puts("Successfully lexed #{source}:")
        print_tokens(tokens)

      {:error, reason} ->
        IO.puts(:stderr, "Lexer error in #{source}: #{reason}")
        System.halt(1)
    end
  end

  # Action function for the 'parse' command (the full pipeline).
  defp parse_and_print(input, source) do
    # This function already expects the Lexer to return an error tuple on failure,
    # but let's make it robust to the raw-list-on-success case as well.
    lexer_result = Lexer.tokenize(input)

    case lexer_result do
      tokens when is_list(tokens) ->
        case Parser.parse(tokens) do
          {:ok, ast} ->
            IO.puts("Successfully parsed #{source}:")
            IO.inspect(ast, pretty: true)
          {:error, reason} ->
            IO.puts(:stderr, "Parser error in #{source}: #{reason}")
            System.halt(1)
        end
      {:error, reason} ->
        IO.puts(:stderr, "Lexer error in #{source}: #{reason}")
        System.halt(1)
    end
  end

  # =============================================================================
  # HELPER FUNCTIONS
  # =============================================================================

  defp print_tokens(tokens) do
    Enum.each(tokens, &print_token/1)
  end

  defp print_token(%Token{type: type, value: nil, line: line, column: col}) do
    IO.puts("#{type} at #{line}:#{col}")
  end

  defp print_token(%Token{type: type, value: value, line: line, column: col}) do
    IO.puts("#{type}(#{inspect(value)}) at #{line}:#{col}")
  end

  defp print_help do
    IO.puts("""
    Scrapex - A toolkit for the ScrapScript language.

    USAGE:
        scrapex <COMMAND> [FILE]
        scrapex --help

    COMMANDS:
        lex           Tokenize the input and print the list of tokens.
        parse         Parse the input and print the final Abstract Syntax Tree (AST).
        eval          (Not implemented) Evaluate the input and print the result.

    ARGS:
        [FILE]        Input file. If not provided, reads from stdin.

    OPTIONS:
        -h, --help    Show this help message.
    """)
  end
end
