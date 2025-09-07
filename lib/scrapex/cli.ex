defmodule Scrapex.CLI do
  @moduledoc """
  Simple command line interface for the Scrapex lexer.
  """

  require Logger
  alias Scrapex.{Lexer, Token, Parser}

  def main(args) do
    case args do
      ["--help"] ->
        print_help()

      ["-h"] ->
        print_help()

      [] ->
        read_stdin()

      [filename] ->
        read_file(filename)

      _ ->
        IO.puts("Error: Too many arguments. Use --help for usage.")
        System.halt(1)
    end
  end

  defp read_stdin do
    IO.read(:stdio, :eof)
    |> process_input("<stdin>")
  end

  defp read_file(filename) do
    case File.read(filename) do
      {:ok, content} ->
        process_input(content, filename)

      {:error, reason} ->
        IO.puts("Error reading file '#{filename}': #{reason}")
        System.halt(1)
    end
  end

  def process_input(input) do
    case Parser.parse(input) do
      # {:ok, ast} ->
      #   # Do something with the successful result
      #   Logger.info("Successfully parsed!")
      #   Logger.info(ast)

      {:error, reason} ->
        # Handle the expected failure case
        IO.puts("Error: #{reason}")
    end
  end

  defp process_input(input, source) do
    try do
      input
      |> Lexer.tokenize()
      |> print_tokens()
    rescue
      error ->
        IO.puts("Lexer error in #{source}: #{Exception.message(error)}")
        System.halt(1)
    end
  end

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
    Logger.info("Hello there!")

    IO.puts("""
    Scrapex - A simple lexer

    USAGE:
        scrapex [FILE]
        scrapex --help

    ARGS:
        [FILE]    Input file to tokenize. If not provided, reads from stdin.

    OPTIONS:
        -h, --help    Show this help message

    EXAMPLES:
        scrapex program.scx         # Tokenize a file
        echo "Hello 123" | scrapex  # Tokenize from stdin
    """)
  end
end
