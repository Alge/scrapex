defmodule Scrapex.Evaluator.Rock.Conversion do
  alias Scrapex.Value
  ############# To Integer ##################
  def apply("to_int", {:text, value}) do
    case Integer.parse(value) do
      {f, _remainder} -> {:ok, Value.integer(f)}
      :error -> {:error, "Cannot convert #{inspect(value)} to integer"}
    end
  end

  def apply("to_int", {:float, value}) do
    {:ok, Value.integer(trunc(value))}
  end

  def apply("to_int", {:hexbyte, value}) do
    {:ok, Value.integer(value)}
  end

  def apply("to_int", value) do
    {:error, "Cannot convert #{inspect(value)} to integer"}
  end

  ############# To Float ##################
  def apply("to_float", {:text, value}) do
    case Float.parse(value) do
      {f, _remainder} -> {:ok, Value.float(f)}
      :error -> {:error, "Cannot convert #{inspect(value)} to float"}
    end
  end

  def apply("to_float", {:integer, value}) do
    {:ok, Value.float(value / 1.0)}
  end

  def apply("to_float", {:hexbyte, value}) do
    {:ok, Value.float(value / 1.0)}
  end

  def apply("to_float", value) do
    {:error, "Cannot convert #{inspect(value)} to float"}
  end

  ############# To Text ##################
  def apply("to_text", {:integer, value}) do
    {:ok, Value.text(Integer.to_string(value))}
  end

  def apply("to_text", {:float, value}) do
    {:ok, Value.text(Float.to_string(value))}
  end

  def apply("to_text", {:hexbyte, value}) do
    {:ok, Value.text("~#{Integer.to_string(value, 16) |> String.pad_leading(2, "0")}")}
  end

  def apply("to_text", {:base64, value}) do
    {:ok, Value.text(value)}
  end

  def apply("to_text", value) do
    {:error, "Cannot convert #{inspect(value)} to text"}
  end

  ############# To List ##################
  def apply("to_list", {:text, text}) do
    chars =
      text
      |> String.graphemes()
      |> Enum.map(&Value.text/1)

    {:ok, Value.list(chars)}
  end

  def apply("to_list", value) do
    {:error, "Cannot convert #{inspect(value)} to list"}
  end

  ############# b64encode ##################
  def apply("b64encode", {:text, value}) do
    {:ok, Base.encode64(value) |> Value.base64()}
  end

  def apply("b64encode", value) do
    {:error, "Cannot encode #{inspect(value)} as base64"}
  end

  ############# b64decode ##################
  def apply("b64decode", {:base64, value}) do
    case Base.decode64(value) do
      {:ok, decoded} -> {:ok, Value.text(decoded)}
      :error -> {:error, "Invalid base64 string: '#{value}'"}
    end
  end

  def apply("b64decode", value) do
    {:error, "Cannot decode #{inspect(value)} from base64"}
  end
end
