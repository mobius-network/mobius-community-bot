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
    user = User.find_or_initialize_by(user_search_criteria)

    return false if user.is_resident == is_resident

    user.update!(is_resident: is_resident)
  end

  private

  def user_search_criteria
    if argument.type == "text_mention"
      { telegram_id: argument.user.id }
    else
      { username: argument.value }
    end
  end

  def argument
    entity = @payload.entities.second
    OpenStruct.new(
      type: entity.type,
      user: entity.user,
      value: argument_value
    )
  end

  def argument_value
    @payload.text.split(" ")[1].sub(/^@/, "")
  end
end
