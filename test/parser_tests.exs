defmodule Scrapex.ParserTest do
  use ExUnit.Case
  alias Scrapex.{Parser, AST}

  test "parse simple integer literal" do
    assert {:ok, result} = Parser.parse("42")
    assert result == AST.integer(42)
  end
end
