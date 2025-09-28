defprotocol Scrapex.Display do
  @moduledoc """
  A protocol for converting ScrapScript runtime values into a displayable string.
  """
  @fallback_to_any true

  @spec to_string(term) :: String.t()
  def to_string(term)
end

# Elixir tuples are the underlying structure for all our values.
# So, we implement the protocol for the built-in Tuple type.
defimpl Scrapex.Display, for: Tuple do
  # The dispatcher function uses pattern matching to figure out
  # which kind of ScrapScript value the tuple represents.
  def to_string({:integer, value}), do: Integer.to_string(value)
  def to_string({:float, value}), do: Float.to_string(value)
  def to_string({:text, value}), do: "\"#{value}\""
  def to_string({:function, nil, _, _}), do: "<function>"
  def to_string({:function, name, _, _}), do: "<function #{name}>"
  def to_string({:record, fields}), do: display_record(fields)
  def to_string({:list, elements}), do: display_list(elements)
  def to_string({:variant, name, nil}), do: "##{name}"

  def to_string({:variant, name, payload}) do
    # Recursively call the protocol to display the payload.
    "##{name} #{Scrapex.Display.to_string(payload)}"
  end

  def to_string(unhandled_value) do
    # This replicates the behavior of your old `case` statement's final clause.
    raise "Don't know how to convert value '#{inspect(unhandled_value)}' to string"
  end

  # --- Private Helper Functions for the Tuple Implementation ---
  # These must be private to this defimpl block.
  defp display_record(fields) do
    field_strings =
      Enum.map(fields, fn {name, value} ->
        "#{name}: #{Scrapex.Display.to_string(value)}"
      end)

    "{#{Enum.join(field_strings, ", ")}}"
  end

  defp display_list(elements) do
    element_strings = Enum.map(elements, &Scrapex.Display.to_string/1)
    "[#{Enum.join(element_strings, ", ")}]"
  end
end

# We can also add an implementation for other types if needed,
# for example, to handle the `nil` for empty variant payloads gracefully,
# although `@fallback_to_any` often handles this.
defimpl Scrapex.Display, for: Atom do
  def to_string(atom) when is_nil(atom), do: "nil"
  def to_string(atom), do: Atom.to_string(atom)
end
