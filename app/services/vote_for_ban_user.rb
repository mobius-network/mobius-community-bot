class VoteForBanUser
  extend LightService::Organizer

  BAN_THRESHOLD = 5
  SAVE_THRESHOLD = 5

  after_actions (->(ctx) {
    if ctx.current_action == ResolveVotingAction && ctx.result != :continue
      ctx.votes_storage.clear
    end
  })

  # @param <Telegram::Bot::Types::User> user_to_ban
  # @param <Telegram::Bot::Types::User> voter
  def self.call(chat_id:, user_to_ban:, voter:, vote: :for)
    with(
      chat_id: chat_id,
      user_to_ban: user_to_ban,
      voter: voter,
      vote: vote.to_sym,
      votes_storage: VotesStorage.new(user_to_ban.id),
    )
      .reduce(
        IncrementVotesCountAction,
        FetchVoteResultsAction,
        ResolveVotingAction,
      )
  end
end
