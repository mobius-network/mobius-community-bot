class FetchTotalSupplyAction
  extend LightService::Action
  promises :total_supply

  executed do |context|
    # context.total_supply = BigDecimal(StellarDEX.asset['amount'])
    context.total_supply = BigDecimal(888000000)
  end
end
