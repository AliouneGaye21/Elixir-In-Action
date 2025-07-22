defmodule TestNum do
  def test(x) when is_number(x) and x < 0 do
    :negative
  end

  def test(x) when x == 0 do
    :zero
  end

  def test(x) when is_number(x) and x > 0 do
    :positive
  end

  test_num =
    fn
      x when is_number(x) and x < 0 -> :negative
      x when x == 0 -> :zero
      x when is_number(x) and x > 0 -> :positive
    end
end
