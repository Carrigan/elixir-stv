defmodule StvTest do
  use ExUnit.Case
  doctest Stv

  test "that can call a simple majority" do
    votes = [[1, 3, 2], [1, 3], [1, 2]]
    assert Stv.top(votes, 1) == [1]
  end

  test "that overflows transfer" do
    votes = [[2, 3], [2, 3], [2, 3], [3], [1]]
    assert Stv.top(votes, 2) == [2, 3]
  end

  test "that when there is no winner, the lowest votes transfer" do
    votes = [[1], [1], [2], [2], [3, 2]]
    assert Stv.top(votes, 1) == [2]
  end

  test "a sufficiently difficult scheme" do
    votes = [[1], [1], [1], [1], [2, 1], [2, 1], [3, 4],
             [3, 4], [3, 4], [3, 4], [3, 4], [3, 4], [3, 4],
             [3, 4], [3, 5], [3, 5], [3, 5], [3, 5], [4], [5]]
    assert Stv.top(votes, 3) == [3, 1, 4]
  end
end
