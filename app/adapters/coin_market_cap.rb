module CoinMarketCap
  API_ENDPOINT = 'https://api.coinmarketcap.com/v1/'
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
    Rails.cache.fetch([:coinmarketcap, :ticker, asset], expires_in: 5.minutes) do
      client.get("ticker/#{asset}/").body
    end
  end
end