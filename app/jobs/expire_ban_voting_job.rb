class ExpireBanVotingJob < ApplicationJob
  include SuckerPunch::Job

  def perform(votes_storage, chat_id, message_id)
    return unless votes_storage.voting_is_ongoing?

    votes_storage.clear

    Telegram.bot.edit_message_text(
      chat_id: chat_id,
      message_id: message_id,
      text: I18n.t("jobs.voting_expired"),
    )
  end
end
