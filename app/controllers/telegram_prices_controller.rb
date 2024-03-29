# frozen_string_literal: true

require 'faraday_middleware'

class TelegramPricesController < TelegramWebhookController
  include ActionView::Helpers::NumberHelper

  def price!(currency = nil, *)
    cmc_price = ->(symbol) { [CoinMarketCap, symbol] }
    cmc_prices = [:usd, :xlm, :btc, :eth].map(&cmc_price)
    text = cmc_prices.map { |(ticker, symbol)| "`#{format_quote(ticker.ask(symbol), symbol)}`"}.join(' = ')

    if currency && currency.downcase.to_sym.in?(TICKERS.keys)
      tickers = TICKERS[currency.downcase.to_sym].map do |ticker|
        if ticker.is_a?(Symbol)
          TICKERS[ticker].map {|tck| [tck, ticker]}
        else
          [[ticker, currency.downcase.to_sym]]
        end
      end.flatten(1)
      text += "\n\n#{tickers.map {|(ticker, symbol)| "➛ #{format_quote(ticker.ask(symbol), symbol)} @ #{ticker.name}"}.join("\n")}"
    end

    respond_with :message, text: text, parse_mode: 'Markdown', disable_notification: true
  end

  def full_price!(*)
    respond_with :message, parse_mode: 'Markdown', disable_notification: true, text: <<-MSG.strip_heredoc
      `/full_price` command is replaced by `/price <asset>` (asset: fiat, xlm, btc or eth)
    MSG
  end

  def supply!(*)
    # 375,559,240.73 are in circulation
    #  - pending remaining pre-sale distributions of 56,906,663.47
    # 124,320,000.00 are locked until October 18, 2018
    # 388,120,759.27 are held by the company for development and other purposes
    result = CalculateCirculatingSupply.call
    respond_with :message, text: <<-MSG.strip_heredoc, parse_mode: 'Markdown'
      `#{format_supply(result.circulating_supply).rjust(16)}` in circulation
      `#{format_supply(result.reserved_supply).rjust(16)}` reserved / locked
      `#{format_supply(result.burned_supply).rjust(16)}` burned
      `#{format_supply(result.total_supply).rjust(16)}` total
    MSG
  end

  def onramps!(*)
    respond_with :message, text: <<-MSG.strip_heredoc, parse_mode: 'Markdown', disable_web_page_preview: true, disable_notification: true
      *Stellar DEX*
       ➛ [StellarX](https://stellarx.com) (XLM, $)
       ➛ [StellarTerm](https://stellarterm.com) (XLM)
       ➛ [Interstellar](https://interstellar.exchange) (XLM, Ƀ, Ł)
       ➛ [StellarPort](https://stellarport.io) (XLM, Ƀ, Ł, Ξ)
       ➛ [FireFly](https://fchain.io) (XLM, ¥)
      *Traditional*
       ➛ [Gate.io](https://gate.io) (USD₮, Ƀ, Ξ)
       ➛ [GOPAX](https://www.gopax.co.kr) (₩)
       ➛ [Bittrex](https://bittrex.com/Market/Index?MarketName=BTC-MOBI) (Ƀ)
       ➛ [Bitmart](https://bitmart.com) (Ξ)
       ➛ [OTC BTC](https://otcbtc.com) (Ƀ, Ξ)
    MSG
  end

  private

  def format_quote(amount, currency)
    return nil unless amount
    amount = BigDecimal(amount.to_s)
    currency = currency.to_sym
    symbol = +SYMBOLS[currency]
    if currency.in? [:btc, :eth]
      amount *= 10**6
      symbol.prepend("μ")
    end
    number_to_currency(
      amount,
      unit: symbol,
      format: '%n %u',
      precision: 3
    )
  end

  def format_supply(amount)
    number_to_currency(amount, unit: 'MOBI', format: '%n %u', precision: 0, delimiter: ',')
  end

  SYMBOLS = { btc: 'Ƀ', ltc: 'Ł', eth: 'Ξ', krw: '₩', usdt: 'USD₮', usd: 'USD', xlm: 'XLM' }.freeze
  TICKERS = {
    usdt: [GateIO],
    xlm: [StellarDEX],
    btc: [GateIO, Bitmart, Bittrex],
    eth: [GateIO, Bitmart, OtcBtc],
    krw: [Gopax],
    fiat: [:usdt, :krw],
  }
end
