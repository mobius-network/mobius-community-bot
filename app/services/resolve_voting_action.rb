class ResolveVotingAction
  extend LightService::Action

  expects :chat_id, :user_to_ban, :for_count, :against_count
  promises :result

  executed do |ctx|
    ctx.result = if ctx.for_count >= VoteForBanUser::BAN_THRESHOLD
                   ban(ctx.user_to_ban) ? :banned : :errored
                 elsif ctx.against_count >= VoteForBanUser::SAVE_THRESHOLD
                   :saved
                 else
                   :continue
                 end
  end

  def self.ban(user)
    User.find_by!(telegram_id: user.id).update(is_muted: true)
  rescue ActiveRecord::RecordNotFound
    User.create(telegram_id: user.id, username: user.username, is_muted: true)
  end
end
