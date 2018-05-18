module StellarDEX
  API_ENDPOINT = 'https://horizon.stellar.org/'.freeze
  MOBI_ASSET = 'MOBI-GA6HCMBLTZS5VYYBCATRBRZ3BZJMAFUDKYYF6AH6MVCMGWMRDNSWJPIH'.freeze

  module_function

  def client
    @client ||= ::Faraday.new(url: API_ENDPOINT) do |faraday|
      faraday.response :json, :content_type => /\bjson$/
      faraday.use FaradayMiddleware::FollowRedirects
      faraday.use :instrumentation
      faraday.adapter :httpclient
    end
  end

  def asset_params(asset, prefix: nil)
    asset_code, asset_issuer = asset.to_s.upcase.split('-')
    asset_type = case asset_code
                 when 'XLM' then :native
                 when ->(v) { v.length <= 4 } then :credit_alphanum4
                 else :credit_alphanum12
                 end
    params = { asset_type: asset_type }
    params.merge!(asset_code: asset_code, asset_issuer: asset_issuer) unless asset_type == :native
    params.transform_keys! { |k| "#{prefix}_#{k}".to_sym } unless prefix.nil?
    params
  end

  def ticker(asset)
    Rails.cache.fetch([:stellardex, :ticker, asset], expires_in: 3.minutes) do
      params = {
          **asset_params(asset, prefix: :buying),
          **asset_params(MOBI_ASSET, prefix: :selling)
      }
      client.get('order_book', **params).body
    end
  end

  def account(address)
    Rails.cache.fetch([:stellardex, :account, address], expires_in: 1.hour) do
      client.get("accounts/#{address.to_s.upcase}").body
    end
  end

  def asset
    Rails.cache.fetch([:stellardex, :asset, :mobi], expires_in: 1.hour) do
      code, issuer = MOBI_ASSET.split('-')
      client.get("assets", asset_code: code, asset_issuer: issuer).body['_embedded']['records'].first
    end
  end
end