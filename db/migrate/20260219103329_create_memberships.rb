class CreateMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.string :role, null: false, default: "tenant_staff"
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :memberships, [ :user_id, :tenant_id ], unique: true
  end
end
