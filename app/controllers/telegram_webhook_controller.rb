class TelegramWebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::TypedUpdate
  include Telegram::Bot::Botan::ControllerHelpers
  include Telegram::Bot::UpdatesController::CallbackQueryContext

  use_session!

  before_action :botan_track_action

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
end
