defmodule Stv do
  @doc """
  Compute winners of an election using the Meek Single Transferable Vote method.

  votes should be given in the format: [[id, id, ...], [id, id, ...], ...]
  seat_count is an integer > 0

  For more info on this computation method, see:
  https://svn.apache.org/repos/asf/steve/trunk/stv_background/meekm.pdf
  """
  def compute([], _), do: []
  def compute(votes, seat_count) do
    Votes.candidates(votes)
    |> Enum.reduce(%{}, fn(x, acc) -> Map.put(acc, x, %{weight: 1, status: :hopeful}) end)
    |> run_cycle(votes, seat_count)
  end

  @doc """
  The main recursive function. Given the statuses of the candidates, settle the
  weights. If there are enough winners, return them. If there are not enough
  winners and there are no more potential candidates, return an empty list as the
  election cannot be determined.
  """
  def run_cycle(state, votes, seat_count) do
    state = settle_weights(state, votes, seat_count)
    winner_list = winners(state)

    cond do
      Enum.count(winner_list) == seat_count ->
        winner_list
      !Candidates.any_electable?(state) ->
        []
      true ->
        exclude_loser(state, apply_weights(state, votes)) |> run_cycle(votes, seat_count)
    end
  end

  @doc """
  Adjust the weights until all elected candidates have their votes settled within
  tolerance of the quota. New candidates are elected if they break the quota.
  """
  def settle_weights(state, votes, seat_count) do
    weighted_votes = apply_weights(state, votes)
    quota = compute_quota(Enum.count(votes), weighted_votes[:excess], seat_count)

    cond do
      weights_settled?(state, quota, weighted_votes, seat_count) ->
        state
      true ->
        elect_above_quota(state, weighted_votes, quota)
        |> update_weights(weighted_votes, quota)
        |> settle_weights(votes, seat_count)
    end
  end

  # Helpers
  defp winners(state) do
    Enum.map(state, fn({id, %{status: status}}) -> if status == :elected, do: id, else: nil end)
    |> Enum.filter(fn(x) -> x != nil end)
  end

  defp exclude_loser(state, weighted_vote) do
    put_in(state, [Candidates.get_loser(state, weighted_vote)], %{weight: 0, status: :excluded})
  end

  defp compute_quota(vote_count, excess, seat_count) do
    (vote_count - excess) / (seat_count + 1)
  end

  defp weights_settled?(s, q, w, c) do
    no_candidates_electable(s, q, w) &&
      (!Candidates.any?(s, :elected) ||
      elected_in_tolerance?(s, q, w)) ||
      Enum.count(winners(s)) == c
  end

  defp no_candidates_electable(state, quota, weighted_votes) do
    Enum.count(Candidates.electable(state, weighted_votes, quota)) == 0
  end

  defp elected_in_tolerance?(state, quota, weighted_votes) do
    Candidates.votes_for(state, :elected, weighted_votes) |> in_tolerance?(quota)
  end

  defp in_tolerance?([], _), do: false
  defp in_tolerance?(elected_votes, quota) do
    Enum.map(elected_votes, fn({_, total}) -> abs(1 - (quota / total)) end)
    |> Enum.all?(fn(diff) -> diff < 0.01 end)
  end

  defp elect_above_quota(state, weighted_votes, quota) do
    Candidates.electable(state, weighted_votes, quota)
    |> Enum.reduce(state, fn(candidate, acc) -> put_in(acc, [candidate, :status], :elected) end)
  end

  defp update_weights(state, weighted_votes, quota) do
    Candidates.votes_for(state, :elected, weighted_votes)
    |> Enum.reduce(state, weight_update_gen(quota))
  end

  defp weight_update_gen(quota) do
    fn({candidate, votes}, state) -> update_in(state, [candidate, :weight], fn(old) -> old * (quota / votes) end) end
  end

  defp weight_map(state) do
    Enum.reduce(state, %{}, fn({id, %{weight: weight}}, acc) -> Map.put(acc, id, weight) end)
  end

  defp apply_weights(state, votes) do
    Votes.apply_weights(votes, weight_map(state))
  end
end
