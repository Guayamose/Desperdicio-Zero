class CreateStockMovements < ActiveRecord::Migration[7.1]
  def change
    create_table :stock_movements do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :inventory_lot, null: false, foreign_key: true
      t.string :movement_type, null: false
      t.decimal :quantity_delta, precision: 10, scale: 2, null: false
      t.string :reason
      t.bigint :performed_by_user_id
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_foreign_key :stock_movements, :users, column: :performed_by_user_id
    add_index :stock_movements, [ :tenant_id, :occurred_at ]
  end
end
