class CreateDailyMenuItems < ActiveRecord::Migration[7.1]
  def change
    create_table :daily_menu_items do |t|
      t.references :daily_menu, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.jsonb :ingredients_json, null: false, default: []
      t.jsonb :allergens_json, null: false, default: []
      t.integer :position, null: false, default: 0

      t.timestamps
    end

  end
end
