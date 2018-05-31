class ChangeResidentStatus
  def initialize(payload)
    @payload = payload
  end

  class << self
    def promote(payload)
      new(payload).call(true)
    end

    def demote(payload)
      new(payload).call(false)
    end
  end

  def call(is_resident)
    user = ExtractUserFromArgs.call(@payload)

    return false if user.is_resident == is_resident

    user.update!(is_resident: is_resident)
  end
end
