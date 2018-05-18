class ResolveVotingAction
  extend LightService::Action

  expects :chat_id, :user_to_ban, :for_count, :against_count
  promises :result

  executed do |ctx|
    ctx.result = if ctx.for_count >= VoteForBanUser::BAN_THRESHOLD
                   ban(ctx.chat_id, ctx.user_to_ban)
                 elsif ctx.against_count >= VoteForBanUser::SAVE_THRESHOLD
                   :saved
                 else
                   :continue
                 end
  end

  def self.ban(chat_id, user)
    if Telegram.bot.kick_chat_member(chat_id: chat_id, user_id: user)
      :banned
    else
      :errored
    end
  end
end
