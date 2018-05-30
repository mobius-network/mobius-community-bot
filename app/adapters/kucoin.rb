module Kucoin
  API_ENDPOINT = 'https://api.kucoin.com/v1'.freeze

  module_function

  def client
    @client ||= ::Faraday.new(url: API_ENDPOINT) do |faraday|
      faraday.response :json, :content_type => /\bjson$/
      faraday.use FaradayMiddleware::FollowRedirects
      faraday.use :instrumentation
      faraday.adapter :httpclient
    end
  end

  def ticker(counter, base: :mobi)
    pair = "#{base}-#{counter}".upcase
    Rails.cache.fetch([:kucoin, :ticker, pair], expires_in: 2.minutes) do
      client.get('open/orders-sell', symbol: pair, limit: 1).body.dig('data')
    end
  end

  def ask(counter, **options)
    ticker(counter, **options).dig(0, 0)
  end

  def name
    'kucoin.com'
  end
end