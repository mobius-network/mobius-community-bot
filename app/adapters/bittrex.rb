module Bittrex
  API_ENDPOINT = 'https://bittrex.com/api/v1.1/public/'

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
    pair = "#{counter}-#{base}".downcase
    Rails.cache.fetch([:bittrex, :ticker, pair], expires_in: 1.minute) do
      client.get("getticker", market: pair).body
    end
  end

  def ask(counter, **options)
    ticker(counter, **options).dig('result', 'Ask')
  end

  def name
    'bittrex.com'
  end
end