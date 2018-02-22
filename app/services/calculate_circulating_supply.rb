class CalculateCirculatingSupply
  extend LightService::Organizer

  def self.call
    reduce(
      FetchTotalSupplyAction,
      FetchReserveAccountsAction,
      CalculateReservesAction
    )
  end
end
