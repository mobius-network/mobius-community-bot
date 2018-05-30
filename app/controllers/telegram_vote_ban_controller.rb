class TelegramVoteBanController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::TypedUpdate
  include Telegram::Bot::Botan::ControllerHelpers
  include Telegram::Bot::UpdatesController::CallbackQueryContext

  use_session!

  before_action :botan_track_action
  before_action :require_group_chat, only: %i[promote demote]
  before_action :require_admin_or_creator, only: %i[promote demote]

  def promote(username = nil, *)
    return reply_with(:message, text: t(".username_is_missing")) if username.nil?

    was_promoted = ChangeResidentStatus.promote(payload)

    reply = was_promoted ? ".promoted" : ".already_promoted"
    reply_with(:message, text: t(reply, user: username))
  end

  def demote(username = nil, *)
    return reply_with(:message, text: t(".username_is_missing")) if username.nil?

    was_demoted = ChangeResidentStatus.demote(payload)

    reply = was_demoted ? ".demoted" : ".was_not_promoted"
    reply_with(:message, text: t(reply, user: username))
  end

  def ban(*)
    user_to_ban = payload.reply_to_message.from

    if User.residents.exists?(telegram_id: user_to_ban.id)
      return respond_with(
        :message,
        text: t(".cannot_ban_residents", user_to_ban: user_to_ban.username || user_to_ban.id),
      )
    end

    if user_is_admin_or_creator?(user_to_ban)
      return respond_with(
        :message,
        text: t(".cannot_ban_admin", user_to_ban: user_to_ban.username || user_to_ban.id),
      )
    end

    context = VoteForBanUser.call(
      chat_id: chat.id,
      user_to_ban: user_to_ban,
      voter: payload.from,
      vote: VotesStorage::VOTE_FOR
    )

    message = t(
      ".message",
      initiator: from.username,
      user_to_ban: user_to_ban.username || user_to_ban.id,
    )

    response = respond_with(
      :message,
      text: message,
      reply_to_message_id: payload.reply_to_message.message_id,
      reply_markup: vote_buttons_markup(context.result)
    )

    ExpireBanVotingJob.perform_in(
      ENV["VOTE_DURATION"]&.to_i || 15 * 60,
      VotesStorage.new(user_to_ban.id),
      chat.id,
      response.dig("result", "message_id"),
    )
  end

  def vote_callback_query(vote)
    user_to_ban = payload.message.reply_to_message.from

    context = VoteForBanUser.call(
      chat_id: payload.message.chat.id,
      user_to_ban: user_to_ban,
      voter: payload.from,
      vote: vote
    )

    return answer_callback_query(context.message) unless context.success?

    result = context.result

    message = t(
      "telegram_vote_ban.vote_results.#{result.resolution}",
      user_to_ban: user_to_ban.username || user_to_ban.id
    )

    if result.resolution != :continue
      edit_message(:text, text: message)
    else
      edit_message(
        :text,
        text: payload.message.text,
        reply_markup: vote_buttons_markup(result)
      )
    end
  end

  private

  def user_is_admin_or_creator?(user)
    UserInfo.new(user.id).status(chat.id).in?(%w[administrator creator])
  end

  def require_admin_or_creator
    return if user_is_admin_or_creator?(from)
    reply_with(:message, text: t(".access_denied"))
    throw :abort
  end

  def require_group_chat
    return if chat.type != "private"
    respond_with(:message, text: t(".use_only_in_group"))
    throw :abort
  end

  def vote_buttons_markup(votes_results)
    ban_btn_text =
      "Ban (%{votes_for_count}/%{votes_for_threshold})" % votes_results.to_h
    save_btn_text =
      "Save (%{votes_against_count}/%{votes_against_threshold})" % votes_results.to_h

    {
      inline_keyboard: [
        [
          { text: ban_btn_text, callback_data: "vote:#{VotesStorage::VOTE_FOR}" },
          { text: save_btn_text, callback_data: "vote:#{VotesStorage::VOTE_AGAINST}" },
        ]
      ]
    }
  end
end
