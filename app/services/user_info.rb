class UserInfo
  def initialize(user_id)
    @user_id = user_id
  end

  def status(chat_id)
    api_response =
      Telegram.bot.get_chat_member(user_id: @user_id, chat_id: chat_id)
    api_response.dig("result", "status")
  end
end
