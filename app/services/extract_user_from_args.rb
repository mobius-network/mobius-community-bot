class ExtractUserFromArgs
  def initialize(payload)
    @payload = payload
  end

  class << self
    def call(payload)
      new(payload).call
    end
  end

  def call
    User.find_or_initialize_by(user_search_criteria)
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
