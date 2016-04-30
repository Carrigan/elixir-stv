defmodule Stv do
  # Votes is in the form [[1, 2, 3], [3, 2, 1], ...]
  def run(votes, seat_count) do
    run(votes, seat_count, [])
  end

  def run(votes, seat_count, winners) do
    winner_count = Enum.count(winners)
    cond do
      winner_count == seat_count -> Enum.reverse(winners)
      true -> single_cycle(votes, seat_count, winners)
    end
  end

  def single_cycle([], _, winners), do: winners

  def single_cycle(votes, seat_count, winners) do
    [{winner, vote_count} | rest] = count_votes(votes)

    cond do
      vote_count >= threshold(votes, seat_count) ->
        declare_winner(votes, seat_count, winner, vote_count, winners)
      true ->
        [{loser, _} | _] = Enum.reverse(rest)
        knockout_loser(votes, seat_count, loser, winners)
    end
  end

  def count_votes(votes) do
    votes
    |> Enum.map(fn([first | _rest]) -> first end)
    |> Enum.reduce(%{}, fn(x, acc) -> Map.update(acc, x, 1, fn(x) -> x + 1 end) end)
    |> Map.to_list
    |> Enum.sort_by(fn({_candidate, vote_count}) -> -vote_count end)
  end

  def declare_winner(votes, seat_count, candidate, votes_received, winners) do
    above_threshold = votes_received - threshold(votes, seat_count)

    overflow_votes = votes
      |> sample_overflow_votes(candidate, above_threshold)
      |> strip_first_candidate()

    without_candidate = votes
      |> Enum.filter(fn([primary | _rest]) -> primary != candidate end)

    run(without_candidate ++ overflow_votes, seat_count, [candidate | winners])
  end

  def sample_overflow_votes(votes, candidate, above_threshold) do
    # TODO: Since we have a small sample count, make this proportional instead of random
    votes
    |> for_candidate(candidate)
    |> with_second_choices()
    |> Enum.shuffle()
    |> Enum.take(above_threshold)
  end

  def knockout_loser(votes, seat_count, loser, winners) do
    votes
    |> for_candidate(loser)
    |> with_second_choices()
    |> strip_first_candidate
    |> single_cycle(seat_count, winners)
  end

  defp strip_first_candidate(vote) do
    Enum.map(vote, fn([_primary | rest]) -> rest end)
  end

  def threshold(votes, seat_count) do
    div(Enum.count(votes), (seat_count + 1)) + 1
  end

  defp for_candidate(votes, candidate) do
    Enum.filter(votes, fn([priority | _rest]) -> priority == candidate end)
  end

  defp with_second_choices(votes) do
    Enum.filter(votes, fn(vote) -> Enum.fetch(vote, 1) |> exists? end)
  end

  defp exists?({:ok, _val}), do: true
  defp exists?(:error), do: false
end
