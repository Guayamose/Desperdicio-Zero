class MenuGeneration < ApplicationRecord
  include TenantScoped

  belongs_to :requested_by, class_name: "User", foreign_key: :requested_by_user_id, optional: true

  enum :status, {
    queued: "queued",
    running: "running",
    succeeded: "succeeded",
    failed: "failed",
    fallback_manual: "fallback_manual"
  }, default: :queued, validate: true

  validates :prompt_version, presence: true
end
