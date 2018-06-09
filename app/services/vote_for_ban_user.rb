class VoteForBanUser
  extend LightService::Organizer

  after_actions (->(ctx) {
    if ctx.current_action == ResolveVotingAction && ctx.result.resolution != :continue
      ctx.votes_storage.clear
    end
  })

  # @param <User> user_to_ban
  # @param <Telegram::Bot::Types::User> voter
  def self.call(chat_id:, user_to_ban_id:, voter:, vote: :for)
    with(
      chat_id: chat_id,
      user_to_ban_id: user_to_ban_id,
      voter: voter,
      vote: vote.to_sym,
      votes_storage: VotesStorage.new(user_to_ban_id),
    )
      .reduce(
        IncrementVotesCountAction,
        FetchVoteResultsAction,
        ResolveVotingAction,
      )
  end

  def self.ban_votes_threshold
    ENV["BAN_VOTES_THRESHOLD"]&.to_i || 5
  end

  def self.save_votes_threshold
    ENV["SAVE_VOTES_THRESHOLD"]&.to_i || 5
  end
end
