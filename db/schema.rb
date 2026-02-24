# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_02_24_173204) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "tenant_id"
    t.bigint "actor_user_id"
    t.string "action", null: false
    t.string "entity_type", null: false
    t.bigint "entity_id"
    t.jsonb "metadata_json", default: {}, null: false
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_user_id", "created_at"], name: "index_audit_logs_on_actor_user_id_and_created_at"
    t.index ["tenant_id", "created_at"], name: "index_audit_logs_on_tenant_id_and_created_at"
    t.index ["tenant_id"], name: "index_audit_logs_on_tenant_id"
  end

  create_table "daily_menu_items", force: :cascade do |t|
    t.bigint "daily_menu_id", null: false
    t.string "name", null: false
    t.text "description"
    t.jsonb "ingredients_json", default: [], null: false
    t.jsonb "allergens_json", default: [], null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "servings", default: 1, null: false
    t.integer "repetitions", default: 1, null: false
    t.jsonb "nutrition_json", default: {}, null: false
    t.jsonb "dietary_flags_json", default: [], null: false
    t.text "religious_notes"
    t.jsonb "inventory_usage_json", default: [], null: false
    t.jsonb "cooking_instructions_json", default: {}, null: false
    t.index ["daily_menu_id"], name: "index_daily_menu_items_on_daily_menu_id"
  end

  create_table "daily_menus", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.date "menu_date", null: false
    t.string "title", null: false
    t.text "description"
    t.jsonb "allergens_json", default: [], null: false
    t.string "status", default: "draft", null: false
    t.string "generated_by", default: "manual", null: false
    t.bigint "created_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "nutrition_summary_json", default: {}, null: false
    t.jsonb "dietary_guidance_json", default: {}, null: false
    t.jsonb "planning_notes_json", default: {}, null: false
    t.index ["tenant_id", "menu_date"], name: "index_daily_menus_on_tenant_id_and_menu_date", unique: true
    t.index ["tenant_id", "status"], name: "index_daily_menus_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_daily_menus_on_tenant_id"
  end

  create_table "inventory_lots", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "product_id", null: false
    t.date "expires_on", null: false
    t.decimal "quantity", precision: 10, scale: 2, null: false
    t.string "unit", default: "unit", null: false
    t.string "status", default: "available", null: false
    t.date "received_on"
    t.string "source", default: "other", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_inventory_lots_on_product_id"
    t.index ["tenant_id", "expires_on"], name: "index_inventory_lots_on_tenant_id_and_expires_on"
    t.index ["tenant_id", "product_id"], name: "index_inventory_lots_on_tenant_id_and_product_id"
    t.index ["tenant_id", "status"], name: "index_inventory_lots_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_inventory_lots_on_tenant_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "tenant_id", null: false
    t.string "role", default: "tenant_staff", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_memberships_on_tenant_id"
    t.index ["user_id", "tenant_id"], name: "index_memberships_on_user_id_and_tenant_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "menu_generations", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "requested_by_user_id"
    t.jsonb "input_lot_ids_json", default: [], null: false
    t.string "model"
    t.string "prompt_version", default: "v1", null: false
    t.string "status", default: "queued", null: false
    t.integer "latency_ms"
    t.string "error_code"
    t.text "raw_response_encrypted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id", "created_at"], name: "index_menu_generations_on_tenant_id_and_created_at"
    t.index ["tenant_id", "status"], name: "index_menu_generations_on_tenant_id_and_status"
    t.index ["tenant_id"], name: "index_menu_generations_on_tenant_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "barcode"
    t.string "name", null: false
    t.string "brand"
    t.string "category"
    t.text "ingredients_text"
    t.jsonb "allergens_json", default: [], null: false
    t.jsonb "nutrition_json", default: {}, null: false
    t.string "source", default: "manual", null: false
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["barcode"], name: "index_products_on_barcode", unique: true, where: "(barcode IS NOT NULL)"
    t.index ["source"], name: "index_products_on_source"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "tenant_id", null: false
    t.bigint "inventory_lot_id", null: false
    t.string "movement_type", null: false
    t.decimal "quantity_delta", precision: 10, scale: 2, null: false
    t.string "reason"
    t.bigint "performed_by_user_id"
    t.datetime "occurred_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inventory_lot_id"], name: "index_stock_movements_on_inventory_lot_id"
    t.index ["tenant_id", "occurred_at"], name: "index_stock_movements_on_tenant_id_and_occurred_at"
    t.index ["tenant_id"], name: "index_stock_movements_on_tenant_id"
  end

  create_table "system_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "role", default: "system_admin", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "role"], name: "index_system_roles_on_user_id_and_role", unique: true
    t.index ["user_id"], name: "index_system_roles_on_user_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.string "address"
    t.string "city"
    t.string "region"
    t.string "country"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "contact_email"
    t.string "contact_phone"
    t.jsonb "operating_hours_json", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_tenants_on_slug", unique: true
    t.index ["status"], name: "index_tenants_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "full_name"
    t.string "locale", default: "es", null: false
    t.datetime "gdpr_consent_at"
    t.datetime "last_seen_at"
    t.datetime "blocked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "must_change_password", default: false, null: false
    t.index ["blocked_at"], name: "index_users_on_blocked_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "audit_logs", "tenants"
  add_foreign_key "audit_logs", "users", column: "actor_user_id"
  add_foreign_key "daily_menu_items", "daily_menus"
  add_foreign_key "daily_menus", "tenants"
  add_foreign_key "daily_menus", "users", column: "created_by_user_id"
  add_foreign_key "inventory_lots", "products"
  add_foreign_key "inventory_lots", "tenants"
  add_foreign_key "memberships", "tenants"
  add_foreign_key "memberships", "users"
  add_foreign_key "menu_generations", "tenants"
  add_foreign_key "menu_generations", "users", column: "requested_by_user_id"
  add_foreign_key "stock_movements", "inventory_lots"
  add_foreign_key "stock_movements", "tenants"
  add_foreign_key "stock_movements", "users", column: "performed_by_user_id"
  add_foreign_key "system_roles", "users"
end
