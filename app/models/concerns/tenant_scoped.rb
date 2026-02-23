module TenantScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :tenant

    scope :for_tenant, ->(tenant) { where(tenant_id: tenant.id) }
    scope :for_current_tenant, -> { where(tenant_id: Current.tenant&.id) }

    before_validation :assign_current_tenant, on: :create

    validates :tenant_id, presence: true
  end

  private

  def assign_current_tenant
    self.tenant ||= Current.tenant
  end
end
