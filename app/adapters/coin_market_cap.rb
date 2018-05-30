module CoinMarketCap
  API_ENDPOINT = 'https://api.coinmarketcap.com/v2/'

  SYMBOLS = {
    mobi: 2429,
    xlm: 512
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

  def ticker(counter, base: :mobi)
    symbol_id = SYMBOLS[base.to_sym]
    convert = counter.to_s.upcase
    Rails.cache.fetch([:coinmarketcap, :ticker, "#{base}_#{counter}"], expires_in: 5.minutes) do
      client.get("ticker/#{symbol_id}/", convert: convert).body.dig('data', 'quotes', convert)
    end
  end

  def ask(counter, **options)
    ticker(counter, **options).dig('price')
  end
end