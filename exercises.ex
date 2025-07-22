defmodule Exercises do
  # Try to write these functions first in the non-tail-recursive form, and then convert them to the
  # tail-recursive version.

  # A list_len/1 function that calculates the length of a list

  def list_len([]), do: 0
  def list_len([_ | tail]), do: 1 + list_len(tail)

  # A list_len_tail/1 function that calculates the length of a list using tail recursion
  def list_len_tail(list), do: list_len_tail(list, 0)
  defp list_len_tail([], acc), do: acc
  defp list_len_tail([_ | tail], acc), do: list_len_tail(tail, acc + 1)

  ## A range/2 function that takes two integers, from and to, and returns a list of all integer
  ## numbers in the given range
  def range(from, to) when from <= to do
    [from | range(from + 1, to)]
  end

  def range(_, _), do: []

  # A range_tail/2 function that takes two integers, from and to, and returns a list of all integer
  # numbers in the given range using tail recursion
  def range_tail(from, to), do: range_tail(from, to, [])

  defp range_tail(from, to, acc) when from <= to do
    range_tail(from + 1, to, [from | acc])
  end

  defp range_tail(_, _, acc), do: Enum.reverse(acc)
end
