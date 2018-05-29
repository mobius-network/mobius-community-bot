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

    user = User.find_or_initialize_by(username: username)
    user.update!(is_resident: true)

    reply_with(:message, text: t(".promoted", user: username))
  end

  def demote(username = nil, *)
    return reply_with(:message, text: t(".username_is_missing")) if username.nil?

    User.where(username: username).update_all(is_resident: false)
    reply_with(:message, text: t(".demoted", user: username))
  end

  def voteban(*)
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

    message = t(
      ".message",
      initiator: from.username,
      user_to_ban: user_to_ban.username || user_to_ban.id,
    )

    response = respond_with(
      :message,
      text: message,
      reply_to_message_id: payload.reply_to_message.message_id,
      reply_markup: {
        inline_keyboard: [
          [
            { text: "+", callback_data: "vote:#{VotesStorage::VOTE_FOR}" },
            { text: "-", callback_data: "vote:#{VotesStorage::VOTE_AGAINST}" },
          ],
        ],
      },
    )

    ExpireBanVotingJob.perform_in(
      ENV["VOTE_DURATION"] || 15 * 60,
      VotesStorage.new(user_to_ban.id),
      chat.id,
      response["result"]["message_id"],
    )
  end

  def vote_callback_query(vote)
    user_to_ban = payload.message.reply_to_message.from

    context = VoteForBanUser.call(
      chat_id: payload.message.chat.id,
      user_to_ban: user_to_ban,
      voter: payload.from,
      vote: vote,
    )

    return answer_callback_query(context.message) unless context.success?

    message = t(
      "telegram_vote_ban.vote_results.#{context.result}",
      { user_to_ban: user_to_ban.username || user_to_ban.id }
    )

    if context.result != :continue
      edit_message(:text, text: message)
    else
      answer_callback_query(message)
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
end
