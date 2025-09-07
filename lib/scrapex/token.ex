defmodule Scrapex.Token do
  @moduledoc """
  Represents a lexical token in ScrapScript source code.
  """

  require Logger

  @typedoc """
  Token types that can appear in ScrapScript source.
  """
  @type token_type ::
          :eof
          | :plus
          | :identifier
          | :integer
          | :string
          | :left_paren
          | :right_paren

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
  def new(type, line, column) when is_atom(type) do
    Logger.debug("Creatng '#{type}' token")
    %__MODULE__{type: type, line: line, column: column}
  end

  # def new(type, value, line, column) when is_atom(type) do
  #   %__MODULE__{type: type, value: value, line: line, column: column}
  # end

  @doc """
  Creates a new token with a value (like identifiers, numbers).
  """
  def new(type, value, line, column) when is_atom(type) do
    Logger.debug("Creatng '#{type}' token: #{value}")
    %__MODULE__{type: type, value: value, line: line, column: column}
  end
end
