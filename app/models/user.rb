class User < ApplicationRecord
  scope :residents, -> { where(is_resident: true) }
end
