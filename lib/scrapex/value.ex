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

  #######################################
  ############## Operators ##############
  #######################################

  ##############    Add    ##############
  def add!(a, b) do
    case add(a, b) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  def add({:integer, a}, {:integer, b}) do
    {:ok, integer(a + b)}
  end

  def add({:float, a}, {:float, b}) do
    {:ok, float(a + b)}
  end

  def add(a, b) do
    {:error, "Operator '+' not supported between value '#{inspect(a)}' and '#{inspect(b)}'"}
  end

  ############## Subtract ##############
  def subtract!(a, b) do
    case subtract(a, b) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  def subtract({:integer, a}, {:integer, b}) do
    {:ok, integer(a - b)}
  end

  def subtract({:float, a}, {:float, b}) do
    {:ok, float(a - b)}
  end

  def subtract(a, b) do
    {:error, "Operator '-' not supported between value '#{inspect(a)}' and '#{inspect(b)}'"}
  end

  ############## Multiply ##############
  def multiply!(a, b) do
    case multiply(a, b) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  def multiply({:integer, a}, {:integer, b}) do
    {:ok, integer(a * b)}
  end

  def multiply({:float, a}, {:float, b}) do
    {:ok, float(a * b)}
  end

  def multiply(a, b) do
    {:error, "Operator '*' not supported between value '#{inspect(a)}' and '#{inspect(b)}'"}
  end

  ##############  Divide  ##############
  def divide!(a, b) do
    case divide(a, b) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  # Catch division by zero
  def divide(_, {_, value}) when value in [0, 0.0, -0.0] do
    {:error, "Division by zero"}
  end

  def divide({:integer, a}, {:integer, b}) do
    {:ok, integer(floor(a / b))}
  end

  def divide({:float, a}, {:float, b}) do
    {:ok, float(a / b)}
  end

  def divide(a, b) do
    {:error, "Operator '/' not supported between value '#{inspect(a)}' and '#{inspect(b)}'"}
  end

  ##############  Append  ##############
  def append!(a, b) do
    case append(a, b) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  def append({:text, a}, {:text, b}) do
    {:ok, text("#{a}#{b}")}
  end

  def append(a, b) do
    {:error, "Operator '++' not supported between value '#{inspect(a)}' and '#{inspect(b)}'"}
  end
end
