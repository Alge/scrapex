defmodule Scrapex.LogFormatter do
  def format(level, message, timestamp, metadata) do
    time = format_time(timestamp)
    level_upper = String.upcase(to_string(level))
    module_info = format_module_info(metadata)

    "#{time} [#{level_upper}] #{module_info}#{message}\n"
  end

  defp format_module_info(metadata) do
    case {Keyword.get(metadata, :module), Keyword.get(metadata, :line)} do
      {nil, nil} -> ""
      {module, nil} -> "[#{clean_module_name(module)}] "
      {nil, line} -> "[#{line}] "
      {module, line} -> "[#{clean_module_name(module)}:#{line}] "
    end
  end

  defp clean_module_name(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.replace_prefix("Elixir.", "")
  end

  defp clean_module_name(module), do: module

  defp format_time({{_year, _month, _day}, {hour, minute, second, millisecond}}) do
    :io_lib.format("~2..0w:~2..0w:~2..0w.~3..0w", [hour, minute, second, millisecond])
    |> List.to_string()
  end
end
