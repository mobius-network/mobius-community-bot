module TelegramWebhooksRouter
  module_function

  def dispatch(bot, update)
    return dispatch_callback(bot, update) if update.key?("callback_query")

    message = update.dig("message", "text")

    controller =
      case message
      when %r(^\/(ban|promote|demote))
        TelegramVoteBanController
      when %r(^\/(price|full_price|onramps|supply))
        TelegramPricesController
      else
        TelegramWebhookController
      end

    controller.dispatch(bot, update)
  end

  def dispatch_callback(bot, update)
    TelegramVoteBanController.dispatch(bot, update)
  end
end

Rails.application.routes.draw do
  telegram_webhook TelegramWebhooksRouter
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
