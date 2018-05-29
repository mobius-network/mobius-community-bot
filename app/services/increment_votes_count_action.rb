class IncrementVotesCountAction
  extend LightService::Action

  expects :votes_storage, :voter, :vote

  executed do |ctx|
    ctx.fail_and_return!(:already_voted) if ctx.votes_storage.voted?(ctx.voter.id)

    begin
      ctx.votes_storage.store_vote(ctx.voter.id, ctx.vote)
    rescue VotesStorage::InvalidVoteError
      ctx.fail_and_return!(:wrong_option)
    end
  end
end
