class CreateMenuGenerations < ActiveRecord::Migration[7.1]
  def change
    create_table :menu_generations do |t|
      t.references :tenant, null: false, foreign_key: true
      t.bigint :requested_by_user_id
      t.jsonb :input_lot_ids_json, null: false, default: []
      t.string :model
      t.string :prompt_version, null: false, default: "v1"
      t.string :status, null: false, default: "queued"
      t.integer :latency_ms
      t.string :error_code
      t.text :raw_response_encrypted

      t.timestamps
    end

    add_foreign_key :menu_generations, :users, column: :requested_by_user_id
    add_index :menu_generations, [ :tenant_id, :created_at ]
    add_index :menu_generations, [ :tenant_id, :status ]
  end
end
