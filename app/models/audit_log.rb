class AuditLog < ApplicationRecord
  belongs_to :tenant, optional: true
  belongs_to :actor, class_name: "User", foreign_key: :actor_user_id, optional: true

  validates :action, :entity_type, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
