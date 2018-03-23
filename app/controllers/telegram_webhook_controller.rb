require 'faraday_middleware'

class TelegramWebhookController < Telegram::Bot::UpdatesController
  include ActionView::Helpers::NumberHelper
  include Telegram::Bot::UpdatesController::TypedUpdate
  include Telegram::Bot::Botan::ControllerHelpers
  use_session!

  before_action :botan_track_action

  def start(*)
    respond_with :message, text: t('.hi')
  end

  def price(*)
    mobi = StellarDEX.ticker('XLM')
    xlm = CoinMarketCap.ticker('stellar')[0]

    mobi_xlm = mobi['asks'][0]['price'].to_d
    mobi_usd = mobi_xlm * xlm['price_usd'].to_d
    mobi_btc = mobi_xlm * xlm['price_btc'].to_d

    respond_with :message, parse_mode: 'Markdown', text: <<-MSG.strip_heredoc
      `#{mobi_xlm.truncate(4)} XLM` ♾ `#{(mobi_usd * 100).truncate(2)} ¢` ♾ `#{(mobi_btc * 10**6).truncate(2)} μɃ`
    MSG
  end

  def full_price(*)
    # MOBI-GA6HCMBLTZS5VYYBCATRBRZ3BZJMAFUDKYYF6AH6MVCMGWMRDNSWJPIH
    # MOBI-mobius.network/XLM-native

    mobius = CoinMarketCap.ticker('mobius')

    gate_usdt = GateIO.ticker('mobi_usdt')
    gate_btc = GateIO.ticker('mobi_btc')
    gate_eth = GateIO.ticker('mobi_eth')

    dex_xlm = StellarDEX.ticker('XLM')

    stronghold_btc = StellarDEX.ticker('BTC-GBSTRH4QOTWNSVA6E4HFERETX4ZLSR3CIUBLK7AXYII277PFJC4BBYOG')
    stronghold_eth = StellarDEX.ticker('ETH-GBSTRH4QOTWNSVA6E4HFERETX4ZLSR3CIUBLK7AXYII277PFJC4BBYOG')

    gopax_krw = Gopax.ticker('KRW')
    otcbtc_btc = OtcBtc.ticker('BTC')
    otcbtc_eth = OtcBtc.ticker('ETH')

    bitmart_eth = Bitmart.ticker('ETH').dig('data', 'c', -1)

    respond_with :message, parse_mode: 'Markdown', text: <<-MSG.strip_heredoc
      *Coinmarketcap*
      #{mobius[0]['price_usd'].to_d.truncate(4)} USD ♾ #{BigDecimal(mobius[0]['price_btc']) * 10**6} μɃ

      *Stellar DEX* 
      #{BigDecimal(dex_xlm['asks'][0]['price']).truncate(4)} XLM
            
      *stronghold.co*
      #{BigDecimal(stronghold_btc['asks'][0]['price']) * 10**6} μɃ ♾ #{BigDecimal(stronghold_eth['asks'][0]['price']) * 10**6} μΞ

      *Gate.io*
      #{BigDecimal(gate_usdt['last'].to_s).truncate(4)} USD₮ ♾ #{BigDecimal(gate_btc['last'].to_s) * 10**6} μɃ ♾ #{BigDecimal(gate_eth['last'].to_s) * 10**6} μΞ

      *GOPAX*
      #{BigDecimal(gopax_krw['ask'])} ₩

      *Bitmart*
      #{BigDecimal(bitmart_eth) * 10**6} μΞ

      *OTC-BTC*
      #{BigDecimal(otcbtc_btc['buy']) * 10**6} μɃ ♾ #{BigDecimal(otcbtc_eth['buy']) * 10**6} μΞ
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
    respond_with :message, text: <<-MSG.strip_heredoc, parse_mode: 'Markdown', disable_web_page_preview: true
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

  protected

  # Ignore stale chats.
  def process(*)
    super
  rescue Telegram::Bot::Forbidden
    logger.info {'Reply failed due to stale chat.'}
  end

  # Ignore errors that appears when user sends too much callback queries in a short
  # time period. Seems like telegram drops first queries before app is able to
  # answer them.
  def answer_callback_query(*)
    super
  rescue Telegram::Bot::Error => e
    raise unless e.message.include?('QUERY_ID_INVALID')
    logger.info {"Ignoring telegram error: #{e.message}"}
  end
end
