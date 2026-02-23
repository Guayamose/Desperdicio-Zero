class SystemRole < ApplicationRecord
  belongs_to :user

  enum :role, { system_admin: "system_admin" }, default: :system_admin, validate: true

  validates :user_id, uniqueness: { scope: :role }
end
