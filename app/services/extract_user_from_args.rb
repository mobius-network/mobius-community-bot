class ExtractUserFromArgs
  class MissingMentionError < StandardError; end
  class InvalidMentionError < StandardError; end

  def initialize(payload)
    @payload = payload
  end

  class << self
    def call(payload)
      new(payload).call
    end
  end

  def call
    raise MissingMentionError, missing_mention_error_message if argument_value.nil?
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

    raise InvalidMentionError, invalid_mention_error_message if entity.nil?

    OpenStruct.new(type: entity.type, user: entity.user, value: argument_value)
  end

  def argument_value
    @payload.text.split(" ")[1]&.sub(/^@/, "")
  end

  def invalid_mention_error_message
    I18n.t(
      :invalid_ban_mention,
      mention: argument_value,
      scope: :telegram_vote_ban
    )
  end

  def missing_mention_error_message
    I18n.t(:missing_ban_mention, scope: :telegram_vote_ban)
  end
end
