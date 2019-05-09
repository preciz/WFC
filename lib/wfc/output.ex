defmodule Wfc.Output do
  @moduledoc """
  This module contains the code to create an %Output{} struct from an %Input{} struct and collapse it.

  At any point `to_png` can be used to save the current image of the %Output{} struct.
  """
  alias Wfc.{Output, Input, Tile, Matrix, Bit}

  import Bitwise

  defstruct [:input, :matrix, :size, :all_flags]

  @doc """
  Returns %Output{} ready to be collapsed by `collapse/1`.
  """
  def new(input = %Input{tiles: tiles}, size \\ 64) when is_integer(size) do
    all_flags = tiles |> Enum.reduce(0, fn %Tile{flag: flag}, acc -> acc + flag end)

    %Output{
      input: input,
      matrix: Matrix.atomics_new(64, all_flags),
      size: size,
      all_flags: all_flags
    }
  end

  @doc """
  Returns bitmask at `position` from `matrix`
  """
  def get(%Output{matrix: matrix, size: size}, position) do
    Matrix.atomics_get(matrix, position, size)
  end

  @doc """
  Puts bitmask at `position` into `matrix`.
  """
  def put(%Output{matrix: matrix, size: size}, position, bitmask) do
    Matrix.atomics_put(matrix, position, bitmask, size)
  end

  @doc """
  Collapses lowest possibilities position of matrix.

  If there is no lowest possibilities position left, it returns `%Output{}`.
  """
  def collapse(output = %Output{input: %Input{tiles: tiles}}) do
    case output |> lowest_possibilities_position do
      :none ->
        output

      {{position, possibilities}, _possibilities_count} ->
        %Tile{flag: flag} =
          Tile.filter_by_possibilities(tiles, possibilities) |> Tile.weighted_random_tile()

        put(output, position, flag)

        propagate_neighbours(output, [position])

        collapse(output)
    end
  end

  @doc """
  Returns position with lowest possibilies or `nil` if there is no position with possibilies > 1.
  """
  def lowest_possibilities_position(output = %Output{size: size}) do
    0..(size * size - 1)
    |> Enum.map(fn pos ->
      pos = {div(pos, size), rem(pos, size)}

      value = get(output, pos)

      {{pos, value}, value |> Bit.count_flags()}
    end)
    |> Enum.filter(fn {_, count} -> count > 1 end)
    |> Enum.min_by(&elem(&1, 1), fn -> :none end)
  end

  @doc """
  Propagates constraint changes to affected neighbours and recursively to their neighbours
  """
  def propagate_neighbours(output, to_propagate \\ [], reset_count \\ 1)

  def propagate_neighbours(output, [], _reset_count), do: output

  def propagate_neighbours(output, [position | tl], reset_count) do
    possibilities = output |> get(position)

    case possibilities do
      0 ->
        reset_area(position, output, reset_count)

        neighbours_of_reset_neighbours =
          Matrix.nth_neighbours(position, reset_count + 1, size: output.size)

        propagate_neighbours(
          output,
          Enum.concat(neighbours_of_reset_neighbours, tl),
          reset_count + 1
        )

      _n ->
        further_propagate = do_propagate_neighbours(position, possibilities, output)

        propagate_neighbours(
          output,
          Enum.concat(further_propagate, tl),
          reset_count
        )
    end
  end

  @doc false
  def do_propagate_neighbours(
        {row, col},
        possibilities,
        output = %Output{size: size, input: %Input{tiles: tiles}}
      ) do
    constraints =
      tiles
      |> Tile.filter_by_possibilities(possibilities)
      |> Tile.merge_constraints()

    Matrix.nth_neighbours({row, col}, 1, size: size)
    |> Enum.reduce(
      [],
      fn {n_row, n_col}, further_propagate ->
        n_possibilities = output |> get({n_row, n_col})

        n_relative_position = {n_row - row, n_col - col}

        updated_possibilities = n_possibilities &&& Map.get(constraints, n_relative_position)

        if updated_possibilities == n_possibilities do
          further_propagate
        else
          put(output, {n_row, n_col}, updated_possibilities)

          [{n_row, n_col} | further_propagate]
        end
      end
    )
  end

  @doc """
  Resets an area around and including `position` to `all_flags` to restart collapse

  This is required if a contradiction is reached
  """
  def reset_area(position, output = %Output{size: size, all_flags: all_flags}, reset_count) do
    neighbours_to_reset = Matrix.nth_neighbours(position, 1..reset_count, size: size)

    [position | neighbours_to_reset]
    |> Enum.each(fn pos -> put(output, pos, all_flags) end)
  end

  @doc """
  Saves %Output{} into png
  """
  def to_png(output = %Output{input: %Input{tiles: tiles}, size: size}) do
    {:ok, file} = :file.open("output.png", [:write])

    png =
      :png.create(%{
        size: {size, size},
        mode: {:rgb, 8},
        file: file
      })

    for pos <- 0..(size * size - 1) do
      pos = {div(pos, size), rem(pos, size)}

      get(output, pos)
    end
    |> Enum.map(fn possibilities ->
      %Tile{colors: [[first_pixel | _] | _]} =
        tiles |> Enum.find(fn %Tile{flag: flag} -> flag == possibilities end)

      first_pixel
    end)
    |> Enum.chunk_every(size)
    |> Enum.each(fn row_colors ->
      row_colors =
        row_colors
        |> Enum.map(&for(i <- Tuple.to_list(&1), do: <<i::8>>, into: <<>>))

      :png.append(png, {:row, row_colors})
    end)

    :png.close(png)
    :file.close(file)
  end
end
