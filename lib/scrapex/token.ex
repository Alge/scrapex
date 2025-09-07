defmodule Scrapex.Token do
  @moduledoc """
  Represents a lexical token in ScrapScript source code.

  A token contains the token type, optional value, and source position
  for error reporting and debugging.
  """

  @typedoc """
  All possible token types that can appear in ScrapScript source.
  """
  # End of file
  @type token_type ::
          :eof
          # Literals
          | :integer
          | :float
          | :text
          | :interpolated_text
          | :hexbyte
          | :base64
          | :hole
          # Identifiers
          | :identifier
          # Single character operators
          | :plus
          | :minus
          | :multiply
          | :slash
          | :equals
          | :less_than
          | :greater_than
          | :pipe
          | :colon
          | :semicolon
          | :dot
          | :comma
          | :underscore
          | :exclamation_mark
          | :hashtag
          | :at
          # Brackets and parentheses
          | :left_paren
          | :right_paren
          | :left_brace
          | :right_brace
          | :left_bracket
          | :right_bracket
          # Multi-character operators
          | :double_plus
          | :append
          | :cons
          | :right_arrow
          | :double_arrow
          | :double_colon
          | :double_dot
          | :pipe_forward
          | :pipe_operator
          | :rock

  @typedoc """
  A lexical token with its value and source position.
  """
  @type t :: %__MODULE__{
          type: token_type(),
          value: term(),
          line: pos_integer(),
          column: pos_integer()
        }

  @enforce_keys [:type, :line, :column]
  defstruct [:type, :value, :line, :column]

  @doc """
  Creates a new token without a value (like EOF, punctuation).
  """
  @spec new(token_type(), pos_integer(), pos_integer()) :: t()
  def new(type, line, column) when is_atom(type) and is_integer(line) and is_integer(column) do
    %__MODULE__{type: type, line: line, column: column}
  end

  @doc """
  Creates a new token with a value (like identifiers, numbers).
  """
  @spec new(token_type(), term(), pos_integer(), pos_integer()) :: t()
  def new(type, value, line, column)
      when is_atom(type) and is_integer(line) and is_integer(column) do
    %__MODULE__{type: type, value: value, line: line, column: column}
  end

  @doc """
  Returns a human-readable string representation of the token.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{type: type, value: nil, line: line, column: column}) do
    "#{type} at #{line}:#{column}"
  end

  def to_string(%__MODULE__{type: type, value: value, line: line, column: column}) do
    "#{type}(#{inspect(value)}) at #{line}:#{column}"
  end

  @doc """
  Checks if a token is of a specific type.
  """
  @spec type?(t(), token_type()) :: boolean()
  def type?(%__MODULE__{type: type}, expected_type), do: type == expected_type

  @doc """
  Checks if a token is a literal value.
  """
  @spec literal?(t()) :: boolean()
  def literal?(%__MODULE__{type: type}) do
    type in [:integer, :float, :text, :interpolated_text, :hexbyte, :base64, :hole]
  end

  @doc """
  Checks if a token is an operator.
  """
  @spec operator?(t()) :: boolean()
  def operator?(%__MODULE__{type: type}) do
    type in [
      :plus,
      :minus,
      :multiply,
      :slash,
      :equals,
      :less_than,
      :greater_than,
      :pipe,
      :colon,
      :semicolon,
      :dot,
      :exclamation_mark,
      :hashtag,
      :at,
      :double_plus,
      :append,
      :cons,
      :right_arrow,
      :double_arrow,
      :double_colon,
      :double_dot,
      :pipe_forward,
      :pipe_operator,
      :rock
    ]
  end
end
