require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
# require "action_mailer/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module MobiusBot
  class Application < Rails::Application
    config.load_defaults 5.1
    config.api_only = true
    config.active_job.queue_adapter = :sucker_punch
    config.redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379')

    config.cache_store = :redis_store, "#{config.redis_url}/0/mobius_bot", { expires_in: 90.minutes }
    config.telegram_updates_controller.session_store = :redis_store, { servers: ["#{config.redis_url}/1/mobius_bot"], expires_in: 1.month }
  end
end
