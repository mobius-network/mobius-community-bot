module TelegramWebhooksRouter
  module_function

  def dispatch(bot, update)
    command = update.dig("message", "text")

    return unless command&.starts_with?("/")

    controller =
      case command
      when %r(^\/(voteban|promote|demote))
        TelegramVoteBanController
      when %r(^\/(price|full_price|onramps|supply))
        TelegramPricesController
      else
        TelegramWebhookController
      end

    controller.dispatch(bot, update)
  end
end

Rails.application.routes.draw do
  telegram_webhook TelegramWebhooksRouter
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
