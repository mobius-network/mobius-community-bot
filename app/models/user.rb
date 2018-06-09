class User < ApplicationRecord
  scope :residents, -> { where(is_resident: true) }

  class << self
    def find_or_create(telegram_user)
      instance = find_or_initialize_by(telegram_id: telegram_user.id)
      return instance unless instance.new_record?

      instance.update(
        first_name: telegram_user.first_name,
        last_name: telegram_user.last_name,
        username: telegram_user.username
      )

      instance
    end
  end

  def display_name
    if username
      "@#{username}"
    else
      "#{first_name} #{last_name}".strip
    end
  end
end
