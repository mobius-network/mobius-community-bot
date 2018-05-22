class ExpireBanVotingJob < ApplicationJob
  include SuckerPunch::Job

  def perform(chat_id, message_id)
    Telegram.bot.edit_message_text(
      chat_id: chat_id,
      message_id: message_id,
      text: I18n.t("jobs.voting_expired"),
    )
  end
end
