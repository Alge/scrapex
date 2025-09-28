# lib/scrapex/cli.ex

defmodule Scrapex.CLI do
  @moduledoc """
  Command line interface for the Scrapex toolkit.
  Provides commands to lex, parse, and evaluate ScrapScript.
  """

  alias Scrapex.{Lexer, Parser, Token, Evaluator, Value, Evaluator.Scope}

  require Logger

  def main(args) do
    # Set default log level to warning
    Logger.configure(level: :warning)

    case args do
      ["lex" | rest_args] ->
        run_lex(rest_args)

      ["parse" | rest_args] ->
        run_parse(rest_args)

      ["eval" | rest_args] ->
        run_eval(rest_args)

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

  defp run_eval(args) do
    options_spec = [code: :string]
    command_help = eval_help()
    handle_input(args, options_spec, command_help, &eval_and_print/2)
  end

  # =============================================================================
  # CORE LOGIC
  # =============================================================================

  defp handle_input(args, options_spec, command_help, action_fun) do
    full_options_spec = options_spec ++ [help: :boolean, log_level: :string]

    try do
      {parsed_opts, positional_args} =
        OptionParser.parse!(args,
          switches: full_options_spec,
          aliases: [c: :code, h: :help, l: :log_level]
        )

      # Configure log level if provided
      if log_level = parsed_opts[:log_level] do
        configure_log_level(log_level)
      end

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
      e in [OptionParser.ParseError] ->
        IO.puts(:stderr, "Error: #{Exception.message(e)}")
        IO.puts(command_help)
        System.halt(1)
    end
  end

  # =============================================================================
  # LOG LEVEL CONFIGURATION
  # =============================================================================

  defp configure_log_level(log_level_str) do
    valid_levels = ["debug", "info", "warning", "error", "none"]

    if log_level_str in valid_levels do
      case log_level_str do
        "none" ->
          Logger.configure(level: :none)

        level_str ->
          level_atom = String.to_atom(level_str)
          Logger.configure(level: level_atom)
      end
    else
      IO.puts(
        :stderr,
        "Error: Invalid log level '#{log_level_str}'. Valid levels: #{Enum.join(valid_levels, ", ")}"
      )

      System.halt(1)
    end
  end

  # =============================================================================
  # ACTION FUNCTIONS
  # =============================================================================

  # Action function for the 'lex' command.
  defp lex_and_print(input, source) do
    case Lexer.tokenize(input) do
      tokens when is_list(tokens) ->
        Logger.info("Successfully lexed #{source}:")
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
            Logger.info("Successfully parsed #{source}:")
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

  # Action function for the 'eval' command (the full pipeline).
  defp eval_and_print(input, source) do
    case Lexer.tokenize(input) do
      tokens when is_list(tokens) ->
        case Parser.parse(tokens) do
          {:ok, ast} ->
            # Create empty scope for evaluation
            scope = Scope.empty()

            case Evaluator.eval(ast, scope) do
              {:ok, value} ->
                Logger.info("Successfully evaluated #{source}:")
                IO.puts(Value.display!(value))

              {:error, reason} ->
                IO.puts(:stderr, "Evaluation error in #{source}: #{reason}")
                System.halt(1)
            end

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
        eval          Evaluate the input. Use `scrapex eval --help` for details.

    GLOBAL OPTIONS:
        -l, --log-level LEVEL    Set log level (debug, info, warning, error, none). Default: warning
        -h, --help               Show this help message.
    """)
  end

  defp lex_help do
    """
    USAGE:
        scrapex lex [OPTIONS] [FILE]
        scrapex lex -c "CODE"

    Tokenizes the input from a file, stdin, or a command-line string.

    OPTIONS:
        -c, --code STRING        Provide the input code as a string.
        -l, --log-level LEVEL    Set log level (debug, info, warning, error, none). Default: warning
        -h, --help               Show this help message.
    """
  end

  defp parse_help do
    """
    USAGE:
        scrapex parse [OPTIONS] [FILE]
        scrapex parse -c "CODE"

    Parses the input from a file, stdin, or a command-line string.

    OPTIONS:
        -c, --code STRING        Provide the input code as a string.
        -l, --log-level LEVEL    Set log level (debug, info, warning, error, none). Default: warning
        -h, --help               Show this help message.
    """
  end

  defp eval_help do
    """
    USAGE:
        scrapex eval [OPTIONS] [FILE]
        scrapex eval -c "CODE"

    Evaluates the input from a file, stdin, or a command-line string.

    OPTIONS:
        -c, --code STRING        Provide the input code as a string.
        -l, --log-level LEVEL    Set log level (debug, info, warning, error, none). Default: warning
        -h, --help               Show this help message.
    """
  end
end
