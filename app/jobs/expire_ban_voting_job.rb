class ExpireBanVotingJob < ApplicationJob
  include SuckerPunch::Job

  def perform(votes_storage, chat_id)
    return unless votes_storage.voting_is_ongoing?

    Telegram.bot.edit_message_text(
      chat_id: chat_id,
      message_id: votes_storage.voting_message_id,
      text: I18n.t("jobs.voting_expired"),
    )

    votes_storage.clear
  end
end
