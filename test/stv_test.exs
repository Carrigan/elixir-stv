defmodule StvTest do
  use ExUnit.Case
  doctest Stv

  test "that can call a simple majority" do
    votes = [[1, 3, 2], [1, 3], [1, 2]]
    run_many_times(votes, 1, [1])
  end

  test "that overflows transfer" do
    votes = [[2, 3], [2, 3], [2, 3], [3], [1]]
    run_many_times(votes, 2, [2, 3])
  end

  test "that when there is no winner, the lowest votes transfer" do
    votes = [[1], [1], [2], [2], [3, 2]]
    run_many_times(votes, 1, [2])
  end

  test "a sufficiently difficult scheme" do
    votes = [[1], [1], [1], [1], [2, 1], [2, 1], [3, 4],
             [3, 4], [3, 4], [3, 4], [3, 4], [3, 4], [3, 4],
             [3, 4], [3, 5], [3, 5], [3, 5], [3, 5], [4], [5]]
    run_many_times(votes, 3, [3, 1, 4])
  end

  test "initially no winners, elimination will create one" do
    votes = [[1], [1], [2], [2], [3, 1]]
    run_many_times(votes, 1, [1])
  end

  test "a no win situation" do
    votes = [[1], [2]]
    run_many_times(votes, 1, [])
  end

  def run_many_times(votes, seat_count, expected) do
    Enum.each((1..1000), fn(_) -> assert ran_run(votes, seat_count) |> match_print(expected) end)
  end

  def ran_run(votes, seat_count) do
    votes |> Enum.shuffle() |> Stv.run(seat_count)
  end

  def match_print(list_1, list_2) do
    match = arrays_match(list_1, list_2)
    unless match do
      IO.puts("\n#{IO.inspect list_1}, #{IO.inspect list_2}\n")
    end
    match
  end

  def arrays_match(list_1, list_2) do
    Enum.sort(list_1) == Enum.sort(list_2)
  end
end
