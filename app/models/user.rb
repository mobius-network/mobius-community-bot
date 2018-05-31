class User < ApplicationRecord
  scope :residents, -> { where(is_resident: true) }

  def display_name
    if username
      "@#{username}"
    else
      "#{first_name} #{last_name}".strip
    end
  end
end
