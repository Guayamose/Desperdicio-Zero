class StockMovement < ApplicationRecord
  include TenantScoped

  belongs_to :inventory_lot
  belongs_to :performed_by, class_name: "User", foreign_key: :performed_by_user_id, optional: true

  enum :movement_type, {
    inbound: "in",
    outbound: "out",
    adjustment: "adjustment",
    waste: "waste"
  }, validate: true

  validates :movement_type, :quantity_delta, :occurred_at, presence: true
  validates :quantity_delta, numericality: true
  validate :tenant_matches_inventory_lot

  before_validation :set_defaults

  private

  def set_defaults
    self.occurred_at ||= Time.current
    self.tenant ||= inventory_lot&.tenant
  end

  def tenant_matches_inventory_lot
    return if tenant.blank? || inventory_lot.blank?
    return if tenant_id == inventory_lot.tenant_id

    errors.add(:tenant_id, "must match inventory lot tenant")
  end
end
