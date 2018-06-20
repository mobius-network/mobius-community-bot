class TelegramVoteBanController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::TypedUpdate
  include Telegram::Bot::UpdatesController::CallbackQueryContext

  use_session!

  before_action :require_group_chat, only: %i[promote demote]
  before_action :require_admin_or_creator, only: %i[promote demote]

  def promote!(username = nil, *)
    return reply_with(:message, text: t(".username_is_missing")) if username.nil?

    was_promoted = ChangeResidentStatus.promote(payload)

    reply = was_promoted ? ".promoted" : ".already_promoted"
    reply_with(:message, text: t(reply, user: username))
  end

  def demote!(username = nil, *)
    return reply_with(:message, text: t(".username_is_missing")) if username.nil?

    was_demoted = ChangeResidentStatus.demote(payload)

    reply = was_demoted ? ".demoted" : ".was_not_promoted"
    reply_with(:message, text: t(reply, user: username))
  end

  def ban!(*)
    user_to_ban =
      if payload.reply_to_message
        User.find_or_create(payload.reply_to_message.from)
      else
        ExtractUserFromArgs.call(payload)
      end

    # TODO: as a quickfix for now just ignore a request to ban unknown user
    return unless user_to_ban.telegram_id

    votes_storage = VotesStorage.new(user_to_ban.telegram_id)

    # Delete the vote initiating '/ban' message
    bot.async do
      bot.delete_message(chat_id: chat.id, message_id: payload.message_id)
    end

    if user_to_ban.is_resident?
      return respond_with(
        :message,
        text: t(".cannot_ban_residents", target: user_to_ban.display_name),
      )
    end

    if user_is_admin_or_creator?(user_to_ban.telegram_id)
      return respond_with(
        :message,
        text: t(".cannot_ban_admin", target: user_to_ban.display_name),
      )
    end

    if votes_storage.voting_is_ongoing?
      return respond_with(
        :message,
        text: t(".vote_results.ongoing", link: "t.me/#{chat.username}/#{votes_storage.voting_message_id}")
      )
    end

    context = VoteForBanUser.call(
      chat_id: chat.id,
      user_to_ban_id: user_to_ban.telegram_id,
      voter: from,
      vote: VotesStorage::VOTE_FOR
    )

    # if user is a resident, it can ban instantly, so there will be no need
    # showing buttons for voting, so it's a shortcut
    if context.result.resolution != :continue
      message = t(
        ".vote_results.#{context.result.resolution}",
        target: user_to_ban.display_name,
        voters_for: context.result.voters_for.map(&:display_name).join(", "),
        voters_against: context.result.voters_against.map(&:display_name).join(", ")
      )

      if context.result.resolution == :banned && payload.reply_to_message
        bot.delete_message(chat_id: chat.id, message_id: payload.reply_to_message.message_id)
      end

      return respond_with(:message, text: message)
    end

    message = t(
      ".message",
      initiator: User.find_by_telegram_id(from.id).display_name,
      target: user_to_ban.display_name,
    )

    response = respond_with(
      :message,
      text: message,
      reply_to_message_id: payload.reply_to_message&.message_id,
      reply_markup: vote_buttons_markup(context.result, user_to_ban)
    )

    votes_storage.voting_message_id = response.dig("result", "message_id")

    ExpireBanVotingJob.perform_in(
      ENV["VOTE_DURATION"]&.to_i || 15 * 60,
      votes_storage,
      chat.id
    )
  rescue ExtractUserFromArgs::InvalidMentionError, ExtractUserFromArgs::MissingMentionError => e
    reply_with(:message, text: e.message)
  end

  def vote_callback_query(data)
    return if UserInfo.new(from.id).status(chat.id) == "restricted"

    vote, user_to_ban_id = data.split(":")

    user_to_ban = User.find_by_telegram_id(user_to_ban_id)

    context = VoteForBanUser.call(
      chat_id: chat.id,
      user_to_ban_id: user_to_ban_id,
      voter: from,
      vote: vote
    )

    return answer_callback_query(context.message) unless context.success?

    result = context.result

    if result.resolution != :continue
      message = t(
        "telegram_vote_ban.vote_results.#{result.resolution}",
        target: user_to_ban.display_name,
        voters_for: result.voters_for.map(&:display_name).join(", "),
        voters_against: result.voters_against.map(&:display_name).join(", ")
      )

      offending_msg = payload.message.reply_to_message
      if result.resolution == :banned && offending_msg
        bot.delete_message(chat_id: chat.id, message_id: offending_msg.message_id)
      end

      edit_message(:text, text: message)
    else
      edit_message(
        :text,
        text: payload.message.text,
        reply_markup: vote_buttons_markup(result, user_to_ban)
      )
    end
  end

  private

  # Ignore errors that appears when user sends too much callback queries in a short
  # time period. Seems like telegram drops first queries before app is able to
  # answer them.
  def answer_callback_query(*)
    super
  rescue Telegram::Bot::Error => e
    raise unless e.message.include?('QUERY_ID_INVALID')
    logger.info {"Ignoring telegram error: #{e.message}"}
  end

  # Telegram requires answer to any callback query, so if you just edit
  # the message user will still see spinner in the callback button.
  # This module makes #edit_message automatically answers callback queries
  # with same text.
  def edit_message(type, params = {})
    super
    if type == :text && params[:text] && payload_type == 'callback_query'
      answer_callback_query params[:text]
    end
  end

  def user_is_admin_or_creator?(user_id)
    user_id.present? && UserInfo.new(user_id).status(chat.id).in?(%w[administrator creator])
  end

  def require_admin_or_creator
    return if user_is_admin_or_creator?(from.id)
    reply_with(:message, text: t(".access_denied"))
    throw :abort
  end

  def require_group_chat
    return if chat.type != "private"
    respond_with(:message, text: t(".use_only_in_group"))
    throw :abort
  end

  def vote_buttons_markup(votes_results, user_to_ban)
    ban_btn_text =
      "Ban (%{votes_for_count}/%{votes_for_threshold})" % votes_results.to_h
    save_btn_text =
      "Save (%{votes_against_count}/%{votes_against_threshold})" % votes_results.to_h

    {
      inline_keyboard: [
        [
          { text: ban_btn_text, callback_data: "vote:#{VotesStorage::VOTE_FOR}:#{user_to_ban.telegram_id}" },
          { text: save_btn_text, callback_data: "vote:#{VotesStorage::VOTE_AGAINST}:#{user_to_ban.telegram_id}" },
        ]
      ]
    }
  end
end
