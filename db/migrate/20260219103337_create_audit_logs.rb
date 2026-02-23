class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.references :tenant, foreign_key: true
      t.bigint :actor_user_id
      t.string :action, null: false
      t.string :entity_type, null: false
      t.bigint :entity_id
      t.jsonb :metadata_json, null: false, default: {}
      t.string :ip_address

      t.timestamps
    end

    add_foreign_key :audit_logs, :users, column: :actor_user_id
    add_index :audit_logs, [ :tenant_id, :created_at ]
    add_index :audit_logs, [ :actor_user_id, :created_at ]
  end
end
