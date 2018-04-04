class CalculateReservesAction
  extend LightService::Action
  expects :reserve_accounts, :total_supply
  promises :reserved_supply, :circulating_supply

  executed do |context|
    context.reserved_supply = 0.to_d
    context.reserve_accounts.each do |address|
      account = StellarDEX.account(address)
      balance = Array(account['balances']).find { |bal| bal['asset_code'] == 'MOBI' }
      context.reserved_supply += BigDecimal(balance['balance']) if balance
    end
    context.circulating_supply = context.total_supply - context.reserved_supply
  end
end
