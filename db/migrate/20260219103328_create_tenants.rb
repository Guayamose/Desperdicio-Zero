class CreateTenants < ActiveRecord::Migration[7.1]
  def change
    create_table :tenants do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :status, null: false, default: "active"
      t.string :address
      t.string :city
      t.string :region
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :contact_email
      t.string :contact_phone
      t.jsonb :operating_hours_json, null: false, default: {}

      t.timestamps
    end

    add_index :tenants, :slug, unique: true
    add_index :tenants, :status
  end
end
