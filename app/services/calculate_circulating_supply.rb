class CalculateCirculatingSupply
  extend LightService::Organizer

  def self.call
    reduce(
      FetchReserveAccountsAction,
      CalculateReservesAction
    )
  end
end
