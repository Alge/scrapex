# lib/scrapex/cli.ex

defmodule Scrapex.CLI do
  @moduledoc """
  Command line interface for the Scrapex toolkit.
  Provides commands to lex, parse, and evaluate ScrapScript.
  """

  alias Scrapex.{Lexer, Parser, Token}

  def main(args) do
    case args do
      ["lex" | rest_args] ->
        run_lex(rest_args)

      ["parse" | rest_args] ->
        run_parse(rest_args)

      ["eval" | _rest_args] ->
        run_eval()

      ["--help"] ->
        print_global_help()

      ["-h"] ->
        print_global_help()

      [] ->
        print_global_help()

      [unknown | _] ->
        IO.puts(:stderr, "Error: Unknown command '#{unknown}'. Use --help for usage.")
        System.halt(1)
    end
  end

  # =============================================================================
  # COMMAND HANDLERS
  # =============================================================================

  defp run_lex(args) do
    options_spec = [code: :string]
    command_help = lex_help()
    handle_input(args, options_spec, command_help, &lex_and_print/2)
  end

  defp run_parse(args) do
    options_spec = [code: :string]
    command_help = parse_help()
    handle_input(args, options_spec, command_help, &parse_and_print/2)
  end

  defp run_eval do
    IO.puts("The 'eval' command is not yet implemented.")
  end

  # =============================================================================
  # CORE LOGIC
  # =============================================================================

  defp handle_input(args, options_spec, command_help, action_fun) do
    full_options_spec = options_spec ++ [help: :boolean]

    try do
      # --- THIS IS THE FIX ---
      # OptionParser.parse!/2 returns a 2-element tuple on success.
      {parsed_opts, positional_args} =
        OptionParser.parse!(args, switches: full_options_spec, aliases: [c: :code, h: :help])

      cond do
        parsed_opts[:help] ->
          IO.puts(command_help)

        code = parsed_opts[:code] ->
          action_fun.(code, "<command-line string>")

        positional_args == [] ->
          content = IO.read(:stdio, :eof)
          action_fun.(content, "<stdin>")

        length(positional_args) == 1 ->
          [filename] = positional_args

          case File.read(filename) do
            {:ok, content} ->
              action_fun.(content, filename)

            {:error, reason} ->
              IO.puts(:stderr, "Error reading file '#{filename}': #{:file.format_error(reason)}")
              System.halt(1)
          end

        true ->
          IO.puts(:stderr, "Error: Too many file arguments provided.")
          IO.puts(command_help)
          System.halt(1)
      end
    rescue
      # OptionParser only raises one kind of error.
      e in [OptionParser.ParseError] ->
        IO.puts(:stderr, "Error: #{Exception.message(e)}")
        IO.puts(command_help)
        System.halt(1)
    end
  end

  # Action function for the 'lex' command.
  defp lex_and_print(input, source) do
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
    case Lexer.tokenize(input) do
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

  defp print_tokens(tokens), do: Enum.each(tokens, &print_token/1)

  defp print_token(%Token{type: type, value: nil, line: line, column: col}) do
    IO.puts("#{type} at #{line}:#{col}")
  end

  defp print_token(%Token{type: type, value: value, line: line, column: col}) do
    IO.puts("#{type}(#{inspect(value)}) at #{line}:#{col}")
  end

  defp print_global_help do
    IO.puts("""
    Scrapex - A toolkit for the ScrapScript language.

    USAGE:
        scrapex <COMMAND> [OPTIONS | FILE]
        scrapex --help

    COMMANDS:
        lex           Tokenize the input. Use `scrapex lex --help` for details.
        parse         Parse the input. Use `scrapex parse --help` for details.
        eval          (Not implemented) Evaluate the input.

    GLOBAL OPTIONS:
        -h, --help    Show this help message.
    """)
  end

  defp lex_help do
    """
    USAGE:
        scrapex lex [FILE]
        scrapex lex -c "CODE"

    Tokenizes the input from a file, stdin, or a command-line string.

    OPTIONS:
        -c, --code STRING     Provide the input code as a string.
        -h, --help            Show this help message.
    """
  end

  defp parse_help do
    """
    USAGE:
        scrapex parse [FILE]
        scrapex parse -c "CODE"

    Parses the input from a file, stdin, or a command-line string.

    OPTIONS:
        -c, --code STRING     Provide the input code as a string.
        -h, --help            Show this help message.
    """
  end
end
