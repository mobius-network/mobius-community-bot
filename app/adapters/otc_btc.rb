module OtcBtc
  API_ENDPOINT = 'https://bb.otcbtc.com/api/v2/'.freeze

  module_function

  def client
    @client ||= ::Faraday.new(url: API_ENDPOINT) do |faraday|
      faraday.response :json, :content_type => /\bjson$/
      faraday.use FaradayMiddleware::FollowRedirects
      faraday.use :instrumentation
      faraday.adapter :httpclient
    end
  end

  def tickers
    Rails.cache.fetch([:otcbtc, :tickers], expires_in: 1.minute) do
      client.get('tickers').body
    end
  end

  def ticker(asset)
    tickers.dig("mobi_#{asset.to_s.downcase}", 'ticker')
  end
end