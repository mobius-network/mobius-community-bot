class ResolveVotingAction
  extend LightService::Action

  expects :chat_id, :user_to_ban, :for_count, :against_count
  promises :result

  executed do |ctx|
    ctx.result = if ctx.for_count >= VoteForBanUser.ban_votes_threshold
                   ban(ctx.chat_id, ctx.user_to_ban) ? :banned : :errored
                 elsif ctx.against_count >= VoteForBanUser.save_votes_threshold
                   :saved
                 else
                   :continue
                 end
  end

  def self.ban(chat_id, user)
    Telegram.bot.restrict_chat_member(
      chat_id: chat_id,
      user_id: user.id,
      can_send_messages: false,
      can_send_media_messages: false,
      can_send_other_messages: false,
    )
  end
end
