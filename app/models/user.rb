class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  has_many :memberships, dependent: :destroy
  has_many :tenants, through: :memberships
  has_many :system_roles, dependent: :destroy
  has_many :audit_logs, foreign_key: :actor_user_id, dependent: :nullify, inverse_of: :actor
  has_many :created_daily_menus, class_name: "DailyMenu", foreign_key: :created_by_user_id, dependent: :nullify, inverse_of: :created_by
  has_many :requested_menu_generations, class_name: "MenuGeneration", foreign_key: :requested_by_user_id, dependent: :nullify, inverse_of: :requested_by
  has_many :performed_stock_movements, class_name: "StockMovement", foreign_key: :performed_by_user_id, dependent: :nullify, inverse_of: :performed_by

  validates :full_name, presence: true

  def system_admin?
    system_roles.system_admin.exists?
  end

  def active_memberships
    memberships.active.includes(:tenant)
  end

  def active_for_authentication?
    super && blocked_at.blank?
  end

  def inactive_message
    blocked_at.present? ? :locked : super
  end

  def in_tenant?(tenant)
    memberships.active.where(tenant_id: tenant.id).exists?
  end

  def tenant_manager_in?(tenant)
    memberships.active.tenant_manager.where(tenant_id: tenant.id).exists?
  end

  def anonymize_personal_data!
    update!(
      full_name: "Deleted User",
      email: "deleted-user-#{id}@example.invalid",
      gdpr_consent_at: nil,
      blocked_at: Time.current
    )
  end
end
