module GateIO
  API_ENDPOINT = "http://data.gate.io/api2/1".freeze

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
    pair = "#{base}_#{counter}".downcase
    Rails.cache.fetch([:gateio, :ticker, pair], expires_in: 5.minutes) do
      client.get("ticker/#{pair}").body
    end
  end

  def ask(counter, **options)
    ticker(counter, **options).dig('lowestAsk')
  end

  def name
    'gate.io'
  end
end