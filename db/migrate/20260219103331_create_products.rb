class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :barcode
      t.string :name, null: false
      t.string :brand
      t.string :category
      t.text :ingredients_text
      t.jsonb :allergens_json, null: false, default: []
      t.jsonb :nutrition_json, null: false, default: {}
      t.string :source, null: false, default: "manual"
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :products, :barcode, unique: true, where: "barcode IS NOT NULL"
    add_index :products, :source
  end
end
