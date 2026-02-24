class Tenant < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :inventory_lots, dependent: :destroy
  has_many :stock_movements, dependent: :destroy
  has_many :daily_menus, dependent: :destroy
  has_many :menu_generations, dependent: :destroy
  has_many :audit_logs, dependent: :nullify

  enum :status, { active: "active", inactive: "inactive", suspended: "suspended" }, default: :active, validate: true

  before_validation :normalize_operating_hours_json

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :operational, -> { where(status: statuses[:active]) }

  private

  def normalize_operating_hours_json
    hours = operating_hours_json.is_a?(Hash) ? operating_hours_json : {}

    self.operating_hours_json = hours
      .to_h
      .transform_keys(&:to_s)
      .transform_values { |value| value.to_s.strip }
      .reject { |_day, value| value.blank? }
  end
end
