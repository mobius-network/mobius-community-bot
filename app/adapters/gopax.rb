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

  def ticker(asset)
    Rails.cache.fetch([:gopax, :ticker, asset], expires_in: 1.minute) do
      client.get("/trading-pairs/MOBI-#{asset.to_s.upcase}/ticker/").body
    end
  end
end