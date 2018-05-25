require 'faraday_middleware'

class TelegramPricesController < TelegramWebhookController
  include ActionView::Helpers::NumberHelper

  def price(*)
    cmc_usd = CoinMarketCap.ticker(:usd).dig('price')
    cmc_xlm = CoinMarketCap.ticker(:xlm).dig('price')
    cmc_btc = CoinMarketCap.ticker(:btc).dig('price')
    cmc_eth = CoinMarketCap.ticker(:eth).dig('price')

    respond_with :message, parse_mode: 'Markdown', text: <<-MSG.strip_heredoc
      `#{format_quote(cmc_usd, :usd)}` ♾ `#{format_quote(cmc_xlm, :xlm)}` ♾ `#{format_quote(cmc_btc, :btc)}` ♾ `#{format_quote(cmc_eth, :eth)}`
    MSG
  end

  def full_price(*)
    cmc_usd = CoinMarketCap.ticker(:usd).dig('price')
    cmc_xlm = CoinMarketCap.ticker(:xlm).dig('price')
    cmc_btc = CoinMarketCap.ticker(:btc).dig('price')

    gate_usdt = GateIO.ticker(:usdt).dig('lowestAsk')
    gate_btc = GateIO.ticker(:btc).dig('lowestAsk')
    gate_eth = GateIO.ticker(:eth).dig('lowestAsk')

    dex_xlm = StellarDEX.ticker(:xlm).dig('asks', 0, 'price')

    stronghold_btc = StellarDEX.ticker('BTC-GBSTRH4QOTWNSVA6E4HFERETX4ZLSR3CIUBLK7AXYII277PFJC4BBYOG').dig('asks', 0, 'price')
    stronghold_eth = StellarDEX.ticker('ETH-GBSTRH4QOTWNSVA6E4HFERETX4ZLSR3CIUBLK7AXYII277PFJC4BBYOG').dig('asks', 0, 'price')

    gopax_krw = Gopax.ticker(:krw).dig('ask')

    bitmart_eth = Bitmart.ticker(:eth).dig('ask_1')

    otcbtc_eth = OtcBtc.ticker(:eth).dig('sell')

    respond_with :message, parse_mode: 'Markdown', text: <<-MSG.strip_heredoc
      *Coinmarketcap*
      #{format_quote(cmc_usd, :usd)} ♾ #{format_quote(cmc_xlm, :xlm)} ♾ #{format_quote(cmc_btc, :btc)}

      *Stellar DEX*
      #{format_quote(dex_xlm, :xlm)}

      *stronghold.co*
      #{format_quote(stronghold_btc, :btc)} ♾ #{format_quote(stronghold_eth, :eth)}

      *Gate.io*
      #{format_quote(gate_usdt, :usdt)} ♾ #{format_quote(gate_btc, :btc)} ♾ #{format_quote(gate_eth, :eth)}

      *GOPAX*
      #{format_quote(gopax_krw, :krw)}

      *Bitmart*
      #{format_quote(bitmart_eth, :eth)}

      *OTC-BTC*
      #{format_quote(otcbtc_eth, :eth)}
    MSG
  end

  def supply(*)
    # 375,559,240.73 are in circulation
    #  - pending remaining pre-sale distributions of 56,906,663.47
    # 124,320,000.00 are locked until October 18, 2018
    # 388,120,759.27 are held by the company for development and other purposes
    result = CalculateCirculatingSupply.call
    respond_with :message, text: <<-MSG.strip_heredoc, parse_mode: 'Markdown'
      `#{number_with_precision(result.circulating_supply, precision: 0, delimiter: ',')} MOBI` in circulation
      `#{number_with_precision(result.reserved_supply, precision: 0, delimiter: ',')} MOBI` reserved / locked up
      `#{number_with_precision(result.total_supply, precision: 0, delimiter: ',')} MOBI` total
    MSG
  end

  def onramps(*)
    respond_with :message, text: <<-MSG.strip_heredoc, parse_mode: 'Markdown', disable_web_page_preview: true, disable_notification: true
      *Stellar DEX*
       ♾ [StellarTerm](https://stellarterm.com) (XLM)
       ♾ [Interstellar](https://interstellar.exchange) (XLM, Ƀ, Ł)
       ♾ [StellarPort](https://stellarport.io) (XLM)
       ♾ [Stronghold](https://stronghold.co) (Ƀ, Ξ)
       ♾ [FireFly](https://fchain.io) (XLM, ¥)

      *Traditional*
       ♾ [GOPAX](https://www.gopax.co.kr) (₩)
       ♾ [Gate.io](https://gate.io) (USD₮, Ƀ, Ξ)
       ♾ [Bitmart](https://bitmart.com) (Ξ)
       ♾ [OTC BTC](https://otcbtc.com) (Ƀ, Ξ)
    MSG
  end

  private

  def format_quote(amount, currency)
    return nil unless amount
    amount = amount.to_s
    currency = currency.to_sym
    symbol = SYMBOLS[currency]
    case currency
    when :btc, :eth
      "#{BigDecimal(amount) * 10**6} μ#{symbol}"
    when :xlm, :usd, :usdt
      "#{BigDecimal(amount).truncate(4)} #{symbol}"
    else
      "#{BigDecimal(amount)} #{symbol}"
    end
  end

  SYMBOLS = { btc: 'Ƀ', ltc: 'Ł', eth: 'Ξ', krw: '₩', usdt: 'USD₮', usd: 'USD', xlm: 'XLM' }
end
