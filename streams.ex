# Let’s say you have a list of employees, and you need to print each one prefixed by their position
# in the list
defmodule Streams do
  @employees ["Alice", "Bob", "John"]

  # Use  Enum.with_index to index eployees
  def index() do
    Enum.with_index(@employees)
  end

  # use Enum each/2 to format the output
  # the problem here is that Enum.with_index goes through the
  # entire list to produce another list with tuples then
  # Enum.each then performs another iteration
  # through the new list
  def index_and_format() do
    @employees
    |> Enum.with_index()
    |> Enum.each(fn {employee, index} ->
      IO.puts("#{index + 1}. #{employee}")
    end)
  end

  # A stream is a lazy enumerable, which means it produces the actual result on demand
  def createStream() do
    stream = Stream.map([1, 2, 3], fn x -> 2 * x end)
    Enum.to_list(stream)
  end

  # The output is the same, but the list iteration is done only once
  def index_lazy_employees() do
    @employees
    |> Stream.with_index()
    |> Enum.each(fn {employee, index} ->
      IO.puts("#{index + 1}. #{employee}")
    end)
  end

  # input list and prints the square root of only those elements that represent a non-negative
  # number, adding an indexed prefix at the beginning
  def square_positive(list) when is_list(list) do
    list
    |> Stream.filter(&(is_number(&1) and &1 > 0))
    |> Stream.map(&{&1, :math.sqrt(&1)})
    |> Stream.with_index()
    |> Enum.each(fn {{input, result}, index} ->
      IO.puts("#{index + 1}. sqrt(#{input}) = #{result}")
    end)
  end

  # takes a filename and returns the list of all lines from
  # that file that are longer than 80 characters
  def large_lines!(path) do
    File.stream!(path)
    |> Stream.map(&String.trim_trailing(&1, "\n"))
    |> Enum.filter(&(String.length(&1) > 80))
  end

  # Infinite streams
  def produce_infinite() do
    Stream.iterate(1, &(&1 + 1))
  end

  def take_from_infinite(n) when is_integer(n) and n >= 0 do
    natural_numbers = produce_infinite()
    Enum.take(natural_numbers, n)
  end

  # repeatedly read the user’s input from the console, stopping
  # when the user submits the blank input
  def read_user_input() do
    Stream.repeatedly(fn -> IO.gets("> ") end)
    |> Stream.map(&String.trim_trailing(&1, "\n"))
    |> Enum.take_while(&(&1 != ""))
    |> List.to_string()
  end

  ############## ------Exercises----#############################

  # A lines_lengths!/1 that takes a file path and returns a list of
  # numbers, with each number representing the length of the
  # corresponding line from the file.
  def lines_length(path) do
    File.stream!(path)
    |> Stream.map(&String.trim_trailing(&1, "\n"))
    |> Enum.map(&String.length/1)
  end

  def longest_line_length(path) do
    File.stream!(path)
    |> Stream.map(&String.trim_trailing(&1, "\n"))
    |> Stream.map(&String.length/1)
    |> Enum.max()
  end
end
