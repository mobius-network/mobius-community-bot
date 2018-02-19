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

  def ticker(pair)
    Rails.cache.fetch([:gateio, :ticker, pair], expires_in: 5.minutes) do
      client.get("ticker/#{pair.to_s.downcase}").body
    end
  end
end