defmodule Scrapex.Value do
  @type t ::
          {:integer, integer()}
          | {:float, float()}
          | {:text, String.t()}

  def integer(i) when is_integer(i), do: {:integer, i}
  def float(f) when is_float(f), do: {:float, f}
  def text(s) when is_binary(s), do: {:text, s}

  def display!(value) do
    case display(value) do
      {:ok, s} ->
        s

      {:error, reason} ->
        raise reason
    end
  end

  def display({:integer, value}) do
    {:ok, Integer.to_string(value)}
  end

  def display({:float, value}) do
    {:ok, Float.to_string(value)}
  end

  def display({:text, value}) do
    {:ok, value}
  end

  def display(value) do
    {:error, "Don't know how to convert value '#{inspect(value)}' to string"}
  end
end
