class Tenant < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :inventory_lots, dependent: :destroy
  has_many :stock_movements, dependent: :destroy
  has_many :daily_menus, dependent: :destroy
  has_many :menu_generations, dependent: :destroy
  has_many :audit_logs, dependent: :nullify

  enum :status, { active: "active", inactive: "inactive", suspended: "suspended" }, default: :active, validate: true

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :operational, -> { where(status: statuses[:active]) }
end
