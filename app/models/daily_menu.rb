class DailyMenu < ApplicationRecord
  include TenantScoped

  belongs_to :created_by, class_name: "User", foreign_key: :created_by_user_id, optional: true
  has_many :daily_menu_items, -> { order(:position, :id) }, dependent: :destroy

  accepts_nested_attributes_for :daily_menu_items, allow_destroy: true

  enum :status, { draft: "draft", published: "published", archived: "archived" }, default: :draft, validate: true
  enum :generated_by, { ai: "ai", manual: "manual" }, default: :manual, validate: true

  validates :menu_date, :title, presence: true
  validates :menu_date, uniqueness: { scope: :tenant_id }

  scope :today, -> { where(menu_date: Date.current) }
end
