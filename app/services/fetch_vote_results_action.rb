class FetchVoteResultsAction
  extend LightService::Action

  expects :votes_storage
  promises :for_count, :against_count

  executed do |ctx|
    ctx.for_count, ctx.against_count = ctx.votes_storage.fetch_voters.map(&:size)
  end
end
