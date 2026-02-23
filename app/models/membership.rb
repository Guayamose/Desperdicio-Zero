class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :tenant

  enum :role, { tenant_manager: "tenant_manager", tenant_staff: "tenant_staff" }, default: :tenant_staff, validate: true

  validates :user_id, uniqueness: { scope: :tenant_id }
  validates :active, inclusion: { in: [true, false] }

  scope :active, -> { where(active: true) }
end
