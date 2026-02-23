class CreateDailyMenus < ActiveRecord::Migration[7.1]
  def change
    create_table :daily_menus do |t|
      t.references :tenant, null: false, foreign_key: true
      t.date :menu_date, null: false
      t.string :title, null: false
      t.text :description
      t.jsonb :allergens_json, null: false, default: []
      t.string :status, null: false, default: "draft"
      t.string :generated_by, null: false, default: "manual"
      t.bigint :created_by_user_id

      t.timestamps
    end

    add_foreign_key :daily_menus, :users, column: :created_by_user_id
    add_index :daily_menus, [ :tenant_id, :menu_date ], unique: true
    add_index :daily_menus, [ :tenant_id, :status ]
  end
end
