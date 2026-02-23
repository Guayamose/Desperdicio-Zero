class InventoryLot < ApplicationRecord
  include TenantScoped

  belongs_to :product
  has_many :stock_movements, dependent: :destroy

  enum :unit, { kg: "kg", g: "g", l: "l", ml: "ml", unit: "unit" }, default: :unit, validate: true
  enum :status, {
    available: "available",
    reserved: "reserved",
    consumed: "consumed",
    discarded: "discarded",
    expired: "expired"
  }, default: :available, validate: true
  enum :source, { donation: "donation", purchase: "purchase", other: "other" }, default: :other, validate: true

  validates :expires_on, :quantity, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  scope :expiring_by, ->(date) { where(status: statuses[:available]).where(expires_on: ..date) }
  scope :critical_expiration, -> { where(status: statuses[:available], expires_on: Date.current..(Date.current + 2.days)) }
end
