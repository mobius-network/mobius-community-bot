module Stronghold
  ISSUER = 'GBSTRH4QOTWNSVA6E4HFERETX4ZLSR3CIUBLK7AXYII277PFJC4BBYOG'.freeze

  module_function

  def ticker(counter, **options)
    StellarDEX.ticker("#{counter}-#{ISSUER}".upcase, **options)
  end

  def ask(counter, **options)
    ticker(counter, **options).dig('asks', 0, 'price')
  end

  def name
    'stronghold.co'
  end
end