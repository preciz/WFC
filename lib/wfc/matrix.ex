defmodule Wfc.Matrix do
  @moduledoc """
  Defines helper functions for matrices
  """

  @doc """
  Returns `nth` relative neighbour positions for `row` & `col`

  If `:size` option is provided it filters out of bounds positions.
  """
  def nth_neighbours(position, nth, options \\ [])

  def nth_neighbours({row, col}, range = %Range{}, options) do
    Enum.flat_map(range, &nth_neighbours({row, col}, &1, options))
  end

  def nth_neighbours({row_pos, col_pos}, nth, options)
      when is_integer(row_pos) and is_integer(col_pos) and is_integer(nth) and nth > 0 do
    size = options |> Keyword.get(:size)

    row_start = row_pos - nth
    row_stop = row_pos + nth
    col_start = col_pos - nth
    col_stop = col_pos + nth

    top_bottom = for c <- col_start..col_stop, do: [{row_start, c}, {row_stop, c}]
    sides = for r <- (row_start + 1)..(row_stop - 1), do: [{r, col_start}, {r, col_stop}]

    list =
      List.flatten([
        top_bottom,
        sides
      ])

    if size do
      list |> filter_out_of_bound_positions(size)
    else
      list
    end
  end

  @doc """
  Filters positions that are out of bound for a matrix with `size`
  """
  def filter_out_of_bound_positions(positions, size) do
    for {row, col} <- positions, row >= 0, col >= 0, row < size, col < size do
      {row, col}
    end
  end

  @doc false
  def transpose(matrix) when is_list(matrix) do
    matrix
    |> List.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  @doc false
  def rotate(matrix) when is_list(matrix) do
    matrix
    |> transpose
    |> Enum.reverse()
  end

  @doc """
  Returns all four rotations for a matixx
  """
  def all_rotations(matrix) when is_list(matrix) do
    first = matrix |> rotate()
    second = first |> rotate()
    third = second |> rotate()

    [matrix, first, second, third]
  end

  @doc """
  Returns the submatrix that would be overlapped with neighbour matrix from `direction`
  """
  def overlap_from(direction, matrix)

  def overlap_from({0, 0}, matrix), do: matrix

  def overlap_from({-1, col}, matrix) when is_integer(col) and is_list(matrix) do
    overlap_from(
      {0, col},
      matrix |> List.pop_at(-1) |> elem(1)
    )
  end

  def overlap_from({1, col}, matrix) when is_integer(col) and is_list(matrix) do
    overlap_from(
      {0, col},
      matrix |> tl
    )
  end

  def overlap_from({row, -1}, matrix) when is_integer(row) and is_list(matrix) do
    overlap_from(
      {row, 0},
      matrix |> Enum.map(&(List.pop_at(&1, -1) |> elem(1)))
    )
  end

  def overlap_from({row, 1}, matrix) when is_integer(row) and is_list(matrix) do
    overlap_from(
      {row, 0},
      matrix |> Enum.map(&tl/1)
    )
  end

  @doc """
  Streams a "list of lists matrix" with positions as first tuple element and current value as second
  """
  def stream(matrix) when is_list(matrix) do
    matrix
    |> Stream.with_index()
    |> Stream.flat_map(fn {row, row_index} ->
      row
      |> Stream.with_index()
      |> Stream.map(fn {value, col_index} ->
        {{row_index, col_index}, value}
      end)
    end)
  end

  @doc """
  Returns all NxN (`tile_size`) tiles of a matrix
  """
  def tiles(matrix, tile_size) when is_list(matrix) and is_integer(tile_size) do
    max_r = length(matrix) - tile_size
    max_c = length(matrix |> hd) - tile_size

    map = stream(matrix) |> Enum.into(%{})

    for x <- 0..max_r, y <- 0..max_c do
      for r <- 0..(tile_size - 1), c <- 0..(tile_size - 1) do
        map |> Map.get({x + r, y + c})
      end
      |> Enum.chunk_every(tile_size)
    end
  end
end
