module Gopax
  API_ENDPOINT = 'https://api.gopax.co.kr'

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
    Rails.cache.fetch([:gopax, :ticker, pair], expires_in: 1.minute) do
      client.get("/trading-pairs/#{pair}/ticker/").body
    end
  end
end