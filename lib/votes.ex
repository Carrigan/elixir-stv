defmodule Votes do
  @doc "Given a list of votes, return all candidates contained in the votes."
  def candidates(votes) do
    Enum.reduce(votes, [], fn(x, acc) -> x ++ acc end)
    |> Enum.reduce([], fn(x, acc) -> add_unless_contains(acc, x) end)
  end

  @doc "Given a list of votes and a map of type { vote_id: weight }, compute the weighted vote list"
  def apply_weights(votes, weight_map) do
    Enum.map(votes, fn(vote) -> build_weighted(%{}, weight_map, vote, 1) end)
    |> Enum.reduce(%{}, &fold_vote/2)
  end

  # Helpers
  defp fold_vote(totals, weighted_vote) do
    Enum.reduce(weighted_vote, totals, &vote_reduce/2)
  end

  defp vote_reduce({candidate, amount}, totals) do
    Map.update(totals, candidate, amount, fn(x) -> x + amount end)
  end

  defp build_weighted(output, _, [], remaining_power) do
    Map.put(output, :excess, remaining_power)
  end

  defp build_weighted(output, weight_map, [candidate | rest], remaining_power) do
    weighted_vote = get_in(weight_map, [candidate]) * remaining_power
    Map.put(output, candidate, weighted_vote)
    |> build_weighted(weight_map, rest, remaining_power - weighted_vote)
  end

  defp add_unless_contains(list, item) do
    cond do
      Enum.find(list, fn(x) -> x == item end) -> list
      true -> [item | list]
    end
  end
end
