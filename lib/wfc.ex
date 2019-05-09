defmodule Wfc do
  @example_input [
    [{255, 255, 255}, {255, 255, 255}, {255, 255, 255}, {255, 255, 255}],
    [{255, 255, 255}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}],
    [{255, 255, 255}, {0, 0, 0}, {255, 0, 0}, {0, 0, 0}],
    [{255, 255, 255}, {0, 0, 0}, {0, 0, 0}, {0, 0, 0}]
  ]

  def example_input, do: @example_input

  def example do
    @example_input
    |> Wfc.Input.new()
    |> Wfc.Output.new()
    |> Wfc.Output.collapse()
    |> Wfc.Output.to_png()

    IO.puts("Your png is ready!")
  end
end
