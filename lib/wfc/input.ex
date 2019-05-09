defmodule Wfc.Input do
  @moduledoc """
  Creates tiles from the input matrix and defines their constraints and weights.

  The input matrix should be a matrix with RGB tuples like: [[{255, 255, 255}, {0, 0, 0}], ...]

  Usage: Wfc.Input.new(input_matrix)
  """

  alias Wfc.{Input, Tile, Matrix}

  import Bitwise

  defstruct [:matrix, :tiles, :tile_size]

  @doc """
  Returns %Input{} struct that contains everything for Output module to start a collapse.
  """
  def new(input, tile_size \\ 2) when is_list(input) and is_integer(tile_size) do
    %Input{
      matrix: input,
      tiles: tiles(input, tile_size),
      tile_size: tile_size,
    }
  end

  @doc """
  Returns list of all possible tiles from input `matrix`.
  """
  def tiles(matrix, tile_size) when is_list(matrix) and is_integer(tile_size) do
    tiles =
      matrix
      |> Matrix.tiles(tile_size)
      |> Enum.flat_map(&Matrix.all_rotations/1)
      |> Enum.reduce(%{}, fn tile, acc ->
        Map.update(acc, tile, 1, &(&1 + 1))
      end)
      |> Enum.with_index()
      |> Enum.map(fn {{colors, count}, index} ->
        %Tile{flag: 1 <<< index, colors: colors, weight: count}
      end)

    for t <- tiles, do: %Tile{t | constraints: constraints(t, tiles)}
  end

  @directions Matrix.nth_neighbours({0, 0}, 1)

  @doc """
  Defines which neighbours are allowed in which directions relative to current tile `t`.

  Returns a map where keys are the directions and values are the bitmasks of allowed flags in that direction.
  """
  def constraints(t = %Tile{}, tiles) when is_list(tiles) do
    for direction <- @directions, into: %{} do
      {
        direction,
        tiles
        |> Enum.reduce(0, fn t2 = %Tile{}, acc ->
          case Tile.allow_overlap?(direction, t, t2) do
            true -> acc ||| t2.flag
            false -> acc
          end
        end)
      }
    end
  end
end
