module StellarTerm
  API_ENDPOINT = 'https://api.stellarterm.com/v1/'.freeze

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
    Rails.cache.fetch([:stellarterm, :tickers], expires_in: 5.minutes) do
      client.get('ticker.json').body
    end
  end

  def ticker(asset='XLM-native')
    tickers['pairs']["MOBI-mobius.network/#{asset}"]
  end
end