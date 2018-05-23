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

  def voteban(*)
    user_to_ban = payload.reply_to_message.from
    message = t(
      ".message",
      initiator: from.username,
      user_to_ban: user_to_ban.username || user_to_ban.id,
    )

    response = respond_with(
      :message,
      text: message,
      reply_to_message_id: payload.reply_to_message["message_id"],
      reply_markup: {
        inline_keyboard: [
          [
            { text: "+", callback_data: VotesStorage::VOTE_FOR },
            { text: "-", callback_data: VotesStorage::VOTE_AGAINST },
          ],
        ],
      },
    )

    ExpireBanVotingJob.perform_in(
      ENV["VOTE_DURATION"] || 20,
      VotesStorage.new(user_to_ban.id),
      chat.id,
      response["result"]["message_id"],
    )
  end

  def callback_query(data)
    user_to_ban = payload.message.reply_to_message.from

    context = VoteForBanUser.call(
      chat_id: payload.message.chat.id,
      user_to_ban: user_to_ban,
      voter: payload.from,
      vote: data,
    )

    return answer_callback_query(context.message) unless context.success?

    message = t(
      "telegram_webhook.voteban.vote_results.#{context.result}",
      { user_to_ban: user_to_ban.username || user_to_ban.id }
    )

    if context.result != :continue
      edit_message(:text, text: message)
    else
      answer_callback_query(message)
    end
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
