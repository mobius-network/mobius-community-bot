class ApplicationController < ActionController::API
  def supply
    result = CalculateCirculatingSupply.call
    render json: result.to_json
  end
end
