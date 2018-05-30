module Bitmart
  API_ENDPOINT = 'https://api.bitmart.com'.freeze

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
    pair = "#{base}_#{counter}".upcase
    Rails.cache.fetch([:bitmart, :ticker, pair], expires_in: 5.minutes) do
      client.get("ticker/#{pair}/").body
    end
  end

  def ask(counter, **options)
    ticker(counter, **options).dig('ask_1')
  end

  def name
    'bitmart.com'
  end
end