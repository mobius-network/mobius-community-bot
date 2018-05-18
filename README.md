# Mobius Telegram Bot

## Development

```
bin/setup
bin/rails telegram:bot:poller
```

## Exchange Integration

| Exchange | Documentation | Endpoint  | Pairs |
| -------- | ------------- | --------- | ----- |
| [GOPAX](https://gopax.co.kr) | [API Docs](https://gopaxapi.github.io/gopax/) | https://api.gopax.co.kr | MOBI-KRW |
| [Gate.io](https://gate.io) | [API Docs](https://gate.io/api2) | http://data.gate.io/api2/1 | MOBI-USDT, MOBI-BTC, MOBI-ETH
| [OTCBTC](https://otcbtc.com) | [API Docs](https://github.com/otcbtc/otcbtc-exchange-api-doc) | https://bb.otcbtc.com | MOBI-ETH |
| [Coinmarketcap](https://coinmarketcap.com) | [API Docs](https://coinmarketcap.com/api/) | https://api.coinmarketcap.com/v1/ | MOBI-USD, MOBI-XLM |
| [Bitmart](https://www.bitmart.com) | [API Docs](https://github.com/bitmartexchange/bitmart-official-api-docs) | https://api.bitmart.com/api/v1/ | MOBI-ETH | 
| [StellarTerm](https://stellarterm.com) | [API Docs](https://github.com/stellarterm/stellarterm/tree/master/api) | https://api.stellarterm.com/v1/ | MOBI-XLM |
| [Stellar DEX](https://www.stellar.org/developers/guides/concepts/exchange.html) | [API Docs](https://www.stellar.org/developers/horizon/reference/endpoints/orderbook-details.html) | https://horizon.stellar.org/ | MOBI/XLM-native, MOBI/BTC-stronghold.co, MOBI/ETH-stronghold.co
