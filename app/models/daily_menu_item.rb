class DailyMenuItem < ApplicationRecord
  belongs_to :daily_menu

  validates :name, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :servings, numericality: { greater_than_or_equal_to: 1 }
  validates :repetitions, numericality: { greater_than_or_equal_to: 1 }

  def total_servings
    servings.to_i * repetitions.to_i
  end
end
