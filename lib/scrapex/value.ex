defmodule Scrapex.Value do
  alias Scrapex.Evaluator.Scope
  alias Scrapex.AST.Expression

  @type t ::
          {:integer, integer()}
          | {:float, float()}
          | {:text, String.t()}
          | {:list, [t()]}
          | {:function, String.t() | nil, Expression.pattern_match_expression(), Scope.t()}
          | {:variant, String.t(), t() | nil}
          | {:record, [{String.t(), t()}]}

  def integer(i) when is_integer(i), do: {:integer, i}
  def float(f) when is_float(f), do: {:float, f}
  def text(s) when is_binary(s), do: {:text, s}
  def list(l) when is_list(l), do: {:list, l}
  def function(expr, closure), do: {:function, nil, expr, closure}
  def function(name, expr, closure) when is_binary(name), do: {:function, name, expr, closure}
  def variant(name) when is_binary(name), do: {:variant, name, nil}
  def variant(name, payload) when is_binary(name), do: {:variant, name, payload}
  def record(fields) when is_list(fields), do: {:record, fields}

  @doc """
  Returns a string representation of a value.
  Delegates to the `Scrapex.Display` protocol.
  """
  def display(value) do
    try do
      {:ok, Scrapex.Display.to_string(value)}
    rescue
      # Use the Exception.message/1 function to correctly get the error string.
      e in [Protocol.UndefinedError] -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Returns a string representation of a value, raising an error on failure.
  """
  def display!(value) do
    Scrapex.Display.to_string(value)
  end

  #######################################
  ############## Operators ##############
  #######################################

  ##############  Negate   ##############

  def negate!(value) do
    case negate(value) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  def negate({type, value}) when type in [:integer, :float] do
    {:ok, {type, value * -1}}
  end

  def negate(value) do
    {:error, "Cannot negate value: #{inspect(value)}"}
  end

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

  ##############  Append strings  ##############
  def append_text!(a, b) do
    case append_text(a, b) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  def append_text({:text, a}, {:text, b}) do
    {:ok, text("#{a}#{b}")}
  end

  def append_text(a, b) do
    {:error, "Operator '++' not supported between value '#{inspect(a)}' and '#{inspect(b)}'"}
  end

  ##############   Cons   ##############

  def cons!(a, b) do
    case cons(a, b) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  def cons(value, {:list, items}) do
    {:ok, list([value | items])}
  end

  def cons(_value, _not_list) do
    {:error, "Cannot perform cons operation on non-list"}
  end

  ########### Append to list ###########
  def append_to_list!(a, b) do
    case append_to_list(a, b) do
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  def append_to_list({:list, items}, item_value) do
    {:ok, list(items ++ [item_value])}
  end

  def append_to_list(_not_list, _item) do
    {:error, "Cannot append to non-list"}
  end

  #######################################
  ############# Comparisons #############
  #######################################

  ##############  Equals   ##############
  def equal({type, a}, {type, a}) when type in [:text, :integer, :float] do
    {:ok, variant("true")}
  end

  def equal({type, _a}, {type, _b}) when type in [:text, :integer, :float] do
    {:ok, variant("false")}
  end

  def equal({:variant, a, b}, {:variant, a, b}) do
    {:ok, variant("true")}
  end

  def equal({:variant, _, _}, {:variant, _, _}) do
    {:ok, variant("false")}
  end

  def equal(a, b) do
    {:error, "Cannot compare #{inspect(a)} and #{inspect(b)}"}
  end

  #############  Not equals  ############
  def not_equal(a, b) do
    case equal(a, b) do
      {:ok, {:variant, "true", _}} -> {:ok, variant("false")}
      {:ok, _} -> {:ok, variant("true")}
      {:error, reason} -> {:error, reason}
    end
  end

  ##########  Greater Than   ############
  def greater_than({type, a}, {type, b}) when type in [:integer, :float, :text] do
    case a > b do
      true -> {:ok, variant("true")}
      false -> {:ok, variant("false")}
    end
  end

  def greater_than(a, b) do
    {:error, "Cannot compare #{inspect(a)} and #{inspect(b)}"}
  end

  ###########  Less Than   ##############
  def less_than({type, a}, {type, b}) when type in [:integer, :float, :text] do
    case a < b do
      true -> {:ok, variant("true")}
      false -> {:ok, variant("false")}
    end
  end

  def less_than(a, b) do
    {:error, "Cannot compare #{inspect(a)} and #{inspect(b)}"}
  end
end
