defmodule Comprehensions do
  def multiplication_table() do
    for x <- 1..9,
        y <- 1..9,
        into: %{} do
      {{x, y}, x * y}
    end
  end

  def filtered_multiplication_table() do
    for x <- 1..9,
        y <- 1..9,
        x <= y,
        into: %{} do
      {{x, y}, x * y}
    end
  end

  def square_list(list) when is_list(list) do
    for x <- list, do: x * x
  end

  def square_list(_) do
    {:error, "Input non è una lista"}
  end

  def nested_multiplication(x, y) when is_list(x) and is_list(y) do
    for x <- x, y <- y, do: {x, y, x * y}
  end
end
