defmodule Scrapex.AST do


end


defmodule Scrapex.AST.Literal do
  defstruct [:type, :value]
end


defmodule Scrapex.AST.BinaryOp do
  defstruct [:left, :operator, :right]
end


defmodule Scrapex.AST.TextPattern do
  defstruct [:text, :pattern]
end
