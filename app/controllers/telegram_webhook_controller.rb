class TelegramWebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::TypedUpdate
  include Telegram::Bot::Botan::ControllerHelpers
  include Telegram::Bot::UpdatesController::CallbackQueryContext

  use_session!

  before_action :botan_track_action
  before_action :store_sender

  def start(*)
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
  end
end
