defmodule Scrapex.AST.Literal do
  @moduledoc "Literal value nodes in the AST"

  # =============================================================================
  # TYPES
  # =============================================================================

  @type integer_literal :: {:integer, value :: integer()}
  @type float_literal :: {:float, value :: float()}
  @type text_literal :: {:text, value :: String.t()}
  @type interpolated_text_literal :: {:interpolated_text, value :: String.t()}
  @type hex_byte_literal :: {:hex_byte, value :: String.t()}
  @type base64_literal :: {:base64, value :: String.t()}
  @type hole_literal :: {:hole, nil}

  @type t ::
          integer_literal()
          | float_literal()
          | text_literal()
          | interpolated_text_literal()
          | hex_byte_literal()
          | base64_literal()
          | hole_literal()

  # =============================================================================
  # CONSTRUCTORS
  # =============================================================================

  @doc "Create an integer literal"
  def integer(value), do: {:integer, value}

  @doc "Create a float literal"
  def float(value), do: {:float, value}

  @doc "Create a text literal"
  def text(value), do: {:text, value}

  @doc "Create an interpolated text literal"
  def interpolated_text(value), do: {:interpolated_text, value}

  @doc "Create a hex byte literal"
  def hexbyte(value), do: {:hexbyte, value}

  @doc "Create a base64 literal"
  def base64(value), do: {:base64, value}

  @doc "Create a hole literal"
  def hole(), do: {:hole, nil}

  def literal?(token_type)
      when token_type in [:integer, :float, :text, :interpolated_text, :hexbyte, :base64, :hole],
      do: true

  def literal?(_), do: false
end
