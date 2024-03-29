class ResolveVotingAction
  extend LightService::Action

  expects :chat_id, :user_to_ban_id, :for_count, :against_count, :for_voters, :against_voters
  promises :result

  executed do |ctx|
    resolution =
      if ctx.for_count >= VoteForBanUser.ban_votes_threshold
        ban(ctx.chat_id, ctx.user_to_ban_id) ? :banned : :errored
      elsif ctx.against_count >= VoteForBanUser.save_votes_threshold
        :saved
      else
        :continue
      end

    ctx.result =
      OpenStruct.new(vote_results_object(ctx).merge(resolution: resolution))
  end

  def self.vote_results_object(ctx)
    {
      votes_for_count: ctx.for_count,
      votes_against_count: ctx.against_count,
      voters_for: ctx.for_voters,
      voters_against: ctx.against_voters,
      votes_for_threshold: VoteForBanUser.ban_votes_threshold,
      votes_against_threshold: VoteForBanUser.save_votes_threshold
    }
  end

  def self.ban(chat_id, user_id)
    Telegram.bot.restrict_chat_member(
      chat_id: chat_id,
      user_id: user_id,
      can_send_messages: false,
      can_send_media_messages: false,
      can_send_other_messages: false,
    )
  end
end
