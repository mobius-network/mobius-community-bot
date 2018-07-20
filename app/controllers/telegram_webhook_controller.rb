class TelegramWebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::TypedUpdate
  include Telegram::Bot::UpdatesController::CallbackQueryContext

  use_session!

  before_action :store_sender
  before_action :mute_invitees

  def start!(*)
    respond_with :message, text: t('.hi')
  end

  protected

  # Ignore stale chats.
  def process(*)
    super
  rescue Telegram::Bot::Forbidden
    logger.info {'Reply failed due to stale chat.'}
  end

  # Ignore errors that appears when user sends too much callback queries in a short
  # time period. Seems like telegram drops first queries before app is able to
  # answer them.
  def answer_callback_query(*)
    super
  rescue Telegram::Bot::Error => e
    raise unless e.message.include?('QUERY_ID_INVALID')
    logger.info {"Ignoring telegram error: #{e.message}"}
  end

  def store_sender
    user = payload.from
    user_model = User.find_or_initialize_by(telegram_id: user.id)
    user_model.update(
      username: user.username,
      first_name: user.first_name,
      last_name: user.last_name
    )
  rescue ActiveRecord::RecordNotUnique
    User.where(username: user.username).update_all(username: nil)
    retry
  end

  def mute_invitees
    return unless payload.is_a?(Telegram::Bot::Types::Message)

    # FIXME: temorary untill bot is an admin in Chinese other groups
    return unless chat.username == 'mobius_network'

    payload.new_chat_members.each do |user|
      Telegram.bot.restrict_chat_member(
        chat_id: chat.id,
        user_id: user.id,
        until_date: 1.day.from_now.to_i,
        can_send_messages: true,
        can_send_media_messages: false,
        can_send_other_messages: false,
        can_add_web_page_previews: false,
      )
    end
  end
end
