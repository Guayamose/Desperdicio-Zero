class Product < ApplicationRecord
  has_many :inventory_lots, dependent: :restrict_with_error

  enum :source, { openfoodfacts: "openfoodfacts", manual: "manual" }, default: :manual, validate: true

  validates :name, presence: true
  validates :barcode, uniqueness: true, allow_blank: true
end
