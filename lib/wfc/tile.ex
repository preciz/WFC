defmodule Wfc.Tile do
  @moduledoc """
    * flag: is the flag position of the tile in the constraint/possiblities bitmask
    * colors: the color matrix of the tile
    * constraints: in the neighbouring directions which tiles flags are allowed
    * weight: the weight of the tile in the original input, used in weighted_random_tile.
  """

  alias Wfc.{Tile, Matrix}

  import Bitwise

  defstruct([:flag, :colors, :constraints, :weight])

  @doc """
  Merges constraints of `tiles`.
  """
  def merge_constraints(tiles) do
    tiles
    |> Enum.reduce(%{}, fn %Tile{constraints: constraints}, acc ->
      Map.merge(
        acc,
        constraints,
        fn _k, v1, v2 ->
          v1 ||| v2
        end
      )
    end)
  end

  @doc """
  Filters `tiles` by flag in `possiblities`.

  Returns a list of tiles that are possible.
  """
  def filter_by_possibilities(tiles, possiblities, acc \\ [])

  def filter_by_possibilities([], _possiblities, acc), do: acc

  def filter_by_possibilities([hd = %Tile{flag: flag} | tl], possibilities, acc) do
    case (possibilities &&& flag) == flag do
      true -> filter_by_possibilities(tl, possibilities, [hd | acc])
      false -> filter_by_possibilities(tl, possibilities, acc)
    end
  end

  @doc """
  Returns `true` if overlap of tiles equal in `{row, col}` direction, `false` otherwise.
  """
  def allow_overlap?(_direction = {row, col}, %Tile{colors: colors}, %Tile{colors: colors2}) do
    Matrix.overlap_from({row, col}, colors) == Matrix.overlap_from({-row, -col}, colors2)
  end

  @doc """
  Returns a random `%Wfc.Tile{}` from the list of `tiles`.
  """
  def weighted_random_tile(tiles) do
    weight_sum = tiles |> Enum.reduce(0, fn %Tile{weight: weight}, acc -> weight + acc end)

    rand = weight_sum * :rand.uniform()

    tiles
    |> Enum.reduce_while(rand, fn t = %Tile{weight: weight}, rand ->
      if rand < weight do
        {:halt, t}
      else
        {:cont, rand - weight}
      end
    end)
  end
end
