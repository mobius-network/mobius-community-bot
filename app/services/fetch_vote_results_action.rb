class FetchVoteResultsAction
  extend LightService::Action

  expects :votes_storage
  promises :for_count, :against_count

  executed do |ctx|
    for_voters, against_voters = ctx.votes_storage.fetch_voters

    totalizer = proc { |v| User.residents.exists?(telegram_id: v) ? resident_weight : 1 }
    ctx.for_count = for_voters.sum(&totalizer)
    ctx.against_count = against_voters.sum(&totalizer)
  end

  def self.resident_weight
    ENV["RESIDENT_VOTE_WEIGHT"] || 5
  end
end
