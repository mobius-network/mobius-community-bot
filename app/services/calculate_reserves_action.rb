class CalculateReservesAction
  extend LightService::Action
  expects :reserve_accounts, :locked_accounts, :burn_account
  promises :circulating_supply, :reserved_supply, :burned_supply, :total_supply

  executed do |ctx|
    ctx.total_supply = 888_000_000.to_d
    ctx.reserved_supply = 0.to_d
    ctx.burned_supply = 0.to_d

    accounts = ctx.reserve_accounts + ctx.locked_accounts
    accounts.each do |address|
      ctx.reserved_supply += load_mobi_balance(address)
    end

    ctx.burned_supply = load_mobi_balance(ctx.burn_account)

    ctx.circulating_supply = ctx.total_supply - ctx.burned_supply - ctx.reserved_supply
  end

  def self.load_mobi_balance(address)
    account = StellarDEX.account(address)
    balance = Array(account['balances']).find do |bal|
      bal.values_at('asset_code', 'asset_issuer').join('-') == StellarDEX::MOBI_ASSET
    end
    balance ? BigDecimal(balance['balance']) : 0.to_d
  end
end
