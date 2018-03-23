module Bitmart
  API_ENDPOINT = 'https://api.bitmart.com/api/v1/'.freeze
  SYMBOLS = {
    mobi: { eth: 24 },
    xlm: { eth: 23 },
  }

  module_function

  def client
    @client ||= ::Faraday.new(url: API_ENDPOINT) do |faraday|
      faraday.response :json, :content_type => /\bjson$/
      faraday.use FaradayMiddleware::FollowRedirects
      faraday.use :instrumentation
      faraday.adapter :httpclient
    end
  end

  def ticker(asset='ETH')
    return unless symbol = SYMBOLS[:mobi][asset.downcase.to_sym]
    ts = Time.now.to_i

    client.get(
      'market_kline',
      sourceTimeZone: 'GMT+03',
      symbol: symbol,
      step: 5,
      from: ts - 1800,
      to: ts
    ).body
  end
end