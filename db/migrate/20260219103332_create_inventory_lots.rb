class CreateInventoryLots < ActiveRecord::Migration[7.1]
  def change
    create_table :inventory_lots do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.date :expires_on, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.string :unit, null: false, default: "unit"
      t.string :status, null: false, default: "available"
      t.date :received_on
      t.string :source, null: false, default: "other"
      t.text :notes

      t.timestamps
    end

    add_index :inventory_lots, [ :tenant_id, :expires_on ]
    add_index :inventory_lots, [ :tenant_id, :product_id ]
    add_index :inventory_lots, [ :tenant_id, :status ]
  end
end
