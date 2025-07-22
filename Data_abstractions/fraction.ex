defmodule Fraction do
  defstruct a: nil, b: nil

  def new(a, b) do
    %Fraction{a: a, b: b}
  end

  # Get the value of a fraction doing sonme pattern matching
  # It's sure because it takes only Fraction as variable
  def value(%Fraction{a: a, b: b}) do
    a / b
  end

  # clearer, but on the flip side it accepts any map,
  # not just Fraction structs
  def value(fraction) do
    fraction.a / fraction.b
  end

  def add(%Fraction{a: a1, b: b1}, %Fraction{a: a2, b: b2}) do
    new(
      a1 * b2 + a2 * b1,
      b2 * b1
    )
  end
end
