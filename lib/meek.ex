defmodule Meek do
  def compute(votes, seat_count) do
    create_initial_state(votes)
    |> run_cycle(votes, seat_count)
  end

  def create_initial_state(votes) do
    all_candidates(votes)
    |> Enum.reduce(%{}, fn(x, acc) -> Map.put(acc, x, %{weight: 1, status: :hopeful}) end)
  end

  def add_unless_contains(list, item) do
    cond do
      Enum.find(list, fn(x) -> x == item end) -> list
      true -> [item | list]
    end
  end

  def all_candidates(votes) do
    Enum.reduce(votes, [], fn(x, acc) -> x ++ acc end)
    |> Enum.reduce([], fn(x, acc) -> add_unless_contains(acc, x) end)
  end

  def run_cycle(state, votes, seat_count) do
    state = settle_weights(state, votes, seat_count)

    cond do
      elected_count(state) == seat_count ->
        winners(state)
      no_moves?(state) ->
        []
      true ->
        exclude_loser(state, apply_weights(state, votes)) |> run_cycle(votes, seat_count)
    end
  end

  def apply_weights(state, votes) do
    Enum.map(votes, fn(vote) -> build_weighted(%{}, state, vote, 1) end)
    |> Enum.reduce(%{}, &fold_vote/2)
  end

  def fold_vote(totals, weighted_vote) do
    Enum.reduce(weighted_vote, totals, &vote_reduce/2)
  end

  def vote_reduce({candidate, amount}, totals) do
    Map.update(totals, candidate, amount, fn(x) -> x + amount end)
  end

  def build_weighted(output, _, [], remaining_power) do
    Map.put(output, :excess, remaining_power)
  end

  def build_weighted(output, state, [candidate | rest], remaining_power) do
    weighted_vote = get_in(state, [candidate, :weight]) * remaining_power
    Map.put(output, candidate, weighted_vote)
    |> build_weighted(state, rest, remaining_power - weighted_vote)
  end

  def exclude_loser(state, weighted_vote) do
    [{last, _} | _] = get_votes_from(state, :hopeful, weighted_vote)
                      |> Enum.sort_by(fn({_, count}) -> count end)

    put_in(state, [last], %{weight: 0, status: :excluded})
  end

  def no_moves?(state) do
    Enum.all?(state, fn({_, %{status: status}}) -> status == :excluded || status == :elected end)
  end

  def settle_weights(state, votes, seat_count) do
    weighted_votes = apply_weights(state, votes)
    quota = compute_quota(Enum.count(votes), weighted_votes[:excess], seat_count)

    cond do
      weights_settled?(state, quota, weighted_votes) ->
        state
      true ->
        elect_above_quota(state, weighted_votes, quota)
        |> update_weights(weighted_votes, quota)
        |> settle_weights(votes, seat_count)
    end
  end

  def weights_settled?(s, q, w) do
    no_electable_candidates(s, q, w) && (none_elected?(s) || elected_in_tolerance?(s, q, w))
  end

  def none_elected?(state) do
    !Enum.any?(state, fn({_, %{status: status}}) -> status == :elected end)
  end

  def no_electable_candidates(state, quota, weighted_votes) do
    Enum.count(electable_candidates(state, weighted_votes, quota)) == 0
  end

  def elected_in_tolerance?(state, quota, weighted_votes) do
    get_votes_from(state, :elected, weighted_votes) |> in_tolerance?(quota)
  end

  def in_tolerance?([], _), do: false
  def in_tolerance?(elected_votes, quota) do
    Enum.map(elected_votes, fn({_, total}) -> abs(1 - (quota / total)) end)
    |> Enum.all?(fn(diff) -> diff < 0.01 end)
  end

  def get_votes_from(state, status, weighted_votes) do
    state
    |> Enum.map(fn({id, %{status: c_status}}) -> if c_status == status, do: id, else: nil end)
    |> Enum.filter(fn(x) -> x != nil end)
    |> Enum.reduce([], fn(id, acc) -> [{id, weighted_votes[id]} | acc] end)
  end

  def elect_above_quota(state, weighted_votes, quota) do
    electable_candidates(state, weighted_votes, quota)
    |> Enum.reduce(state, fn(candidate, acc) -> put_in(acc, [candidate, :status], :elected) end)
  end

  def elected_count(state) do
    Enum.count(winners(state))
  end

  def winners(state) do
    Enum.map(state, fn({id, %{status: status}}) -> if status == :elected, do: id, else: nil end)
    |> Enum.filter(fn(x) -> x != nil end)
  end

  def electable_candidates(state, weighted_votes, quota) do
    get_votes_from(state, :hopeful, weighted_votes)
    |> Enum.filter(fn({_, total}) -> total >= quota end)
    |> Enum.map(fn({id, _}) -> id end)
  end

  def update_weights(state, weighted_votes, quota) do
    get_votes_from(state, :elected, weighted_votes)
    |> Enum.reduce(state, weight_update_gen(quota))
  end

  def weight_update_gen(quota) do
    fn({candidate, votes}, state) -> update_in(state, [candidate, :weight], fn(old) -> old * (quota / votes) end) end
  end

  def compute_quota(vote_count, excess, seat_count) do
    (vote_count - excess) / (seat_count + 1)
  end
end
