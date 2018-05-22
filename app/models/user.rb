class User < ApplicationRecord
  scope :admins, -> { where(is_admin: true) }
end
