class FetchVoteResultsAction
  extend LightService::Action

  expects :votes_storage
  promises :for_count, :against_count, :for_voters, :against_voters

  executed do |ctx|
    for_voters, against_voters = ctx.votes_storage.fetch_voters

    instantiator = proc { |v| User.find_by_telegram_id(v) }
    ctx.for_voters = for_voters.map(&instantiator)
    ctx.against_voters = against_voters.map(&instantiator)

    totalizer = proc { |u| u.is_resident? ? resident_weight : 1 }
    ctx.for_count = ctx.for_voters.sum(&totalizer)
    ctx.against_count = ctx.against_voters.sum(&totalizer)
  end

  def self.resident_weight
    ENV["RESIDENT_VOTE_WEIGHT"]&.to_i || 5
  end
end
