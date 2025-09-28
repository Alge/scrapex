defmodule Scrapex.Evaluator.Rock.Utility do
  alias Scrapex.Value

  ############# Length ##################
  def apply("length", {:text, value}) do
    {:ok, Value.integer(String.length(value))}
  end

  def apply("length", {:list, items}) do
    {:ok, Value.integer(Enum.count(items))}
  end

  def apply("length", value) do
    {:error, "Cannot get length of #{inspect(value)}"}
  end

  ############# Keys ##################
  def apply("keys", {:record, fields}) do
    keys = Enum.map(fields, fn {key, _value} -> Value.text(key) end)
    {:ok, Value.list(keys)}
  end

  def apply("keys", value) do
    {:error, "Cannot get keys from #{inspect(value)}"}
  end
end
