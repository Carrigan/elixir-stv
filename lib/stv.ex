defmodule Stv do
  # Votes is in the form [[1, 2, 3], [3, 2, 1], ...]
  def top(votes, count) do
    get_counts(votes)
    |> Enum.map(fn({candidate, _votes}) -> candidate end)
    |> Enum.take(count)
  end

  def threshold(votes, count) do
    div(Enum.count(votes), (count + 1)) + 1
  end

  def get_counts(votes) do
    votes
    |> Enum.map(fn([first | _rest]) -> first end)
    |> Enum.reduce(%{}, fn(x, acc) -> Map.update(acc, x, 1, fn(x) -> x + 1 end) end)
    |> Map.to_list
    |> Enum.sort_by(fn({_candidate, vote_count}) -> -vote_count end)
  end
end
