# lib/scrapex/evaluator/rock.ex

defmodule Scrapex.Evaluator.Rock do
  require Logger
  alias Scrapex.Evaluator.Rock.{Conversion, Utility}

  def apply_native_function(func_name, arg_value) do
    Logger.debug("Applying rock #{func_name} to value #{inspect(arg_value)}")

    case func_name do
      name when name in ["to_text", "to_int", "to_float", "b64encode", "b64decode", "to_list"] ->
        Conversion.apply(func_name, arg_value)

      name when name in ["length", "keys"] ->
        Utility.apply(func_name, arg_value)

      _ ->
        {:error, "Unknown native function: $$#{func_name}"}
    end
  end
end
