defmodule Scrapex.Evaluator.Scope do
  defstruct name: nil, value: nil, parent: nil

  @type t :: %__MODULE__{
          name: String.t() | nil,
          value: any(),
          parent: t() | nil
        }

  @spec empty() :: t()
  def empty do
    %__MODULE__{}
  end

  @spec bind(t(), String.t(), any()) :: t()
  def bind(parent_scope, name, value) do
    %__MODULE__{
      name: name,
      value: value,
      parent: parent_scope
    }
  end

  @spec get(t(), String.t()) :: {:ok, any()} | {:error, :not_found}

  def get(%__MODULE__{name: nil}, _name) do
    {:error, :not_found}
  end

  def get(%__MODULE__{name: name, value: value}, name) do
    {:ok, value}
  end

  def get(%__MODULE__{parent: parent}, name) do
    get(parent, name)
  end
end
