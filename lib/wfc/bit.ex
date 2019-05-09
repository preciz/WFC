defmodule Wfc.Bit do
  @moduledoc """
  Defines helpers for bitmasks
  """

  import Bitwise

  @doc """
  Returns count of flags set to 1 in bitmask
  """
  def count_flags(int, acc \\ 0)

  def count_flags(0, acc), do: acc

  def count_flags(int, acc) when is_integer(int) and is_integer(acc) do
    case int &&& 1 do
      0 -> count_flags(int >>> 1, acc)
      1 -> count_flags(int >>> 1, acc + 1)
    end
  end
end
