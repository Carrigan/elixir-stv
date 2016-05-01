defmodule Candidates do
  @doc "Return a map of { id: vote_count, ... } for all candidates with <status>"
  def votes_for(state, status, weighted_votes) do
    Enum.map(state, fn({id, %{status: c_status}}) -> if c_status == status, do: id end)
    |> Enum.filter(fn(x) -> x != nil end)
    |> Enum.reduce([], fn(id, acc) -> [{id, weighted_votes[id]} | acc] end)
  end

  @doc "Return all hopefuls that have a weighted vote above threshold"
  def electable(state, weighted_votes, quota) do
    votes_for(state, :hopeful, weighted_votes)
    |> Enum.filter(fn({_, total}) -> total >= quota end)
    |> Enum.map(fn({id, _}) -> id end)
  end

  @doc "Return if any candidates have <status>"
  def any?(state, status) do
    Enum.any?(state, fn({_, %{status: c_status}}) -> c_status == status end)
  end

  @doc "Return the hopeful with the least number of votes"
  def get_loser(state, weighted_votes) do
    [{last, _} | _] = votes_for(state, :hopeful, weighted_votes)
      |> Enum.sort_by(fn({_, count}) -> count end)
    last
  end

  @doc "Return if any of the candidates left are electable (:hopeful)"
  def any_electable?(state) do
    Enum.any?(state, fn({_, %{status: status}}) -> status == :hopeful end)
  end
end
