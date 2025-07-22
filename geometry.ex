defmodule Geometry do
  defmodule Rectangle do
    def rectangle_area(a, b) do
      a * b
    end

    def square_area(a) do
      rectangle_area(a, a)
    end
  end

  defmodule Circle do
    @moduledoc "Implements basic circle functions"
    @pi 3.14159
    @doc "Computes the area of a circle"
    def area(r), do: r * r * @pi
    @doc "Computes the circumference of a circle"
    def circumference(r), do: 2 * r * @pi
  end

  def area({:rectangle, a, b}) do
    a * b
  end

  def area({:square, a}) do
    a * a
  end

  def area({:circle, r}) do
    r * r * 3.14
  end

  def area(unknown) do
    {:error, {:unknown_shape, unknown}}
  end

  def fattoriale(n) when n == 1 do
    n
  end

  def fattoriale(n) when n > 1 do
    n * fattoriale(n - 1)
  end
end
