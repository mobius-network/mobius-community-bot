class User < ApplicationRecord
  scope :residents, -> { where(is_resident: true) }

  def display_name
    username
  end
end
