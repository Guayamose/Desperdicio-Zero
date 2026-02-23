class CreateSystemRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :system_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "system_admin"

      t.timestamps
    end

    add_index :system_roles, [ :user_id, :role ], unique: true
  end
end
