defmodule Scrapex.Value.TextTest do
  use ExUnit.Case

  alias Scrapex.Value

  describe "text operations" do
    ############## Append Text ##############
    test "text append text" do
      assert Value.append_text!(Value.text("Hello "), Value.text("World")) ==
               Value.text("Hello World")
    end
  end
end
