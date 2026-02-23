class DailyMenuItem < ApplicationRecord
  belongs_to :daily_menu

  validates :name, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
end
