class AddIntelligentFieldsToMenus < ActiveRecord::Migration[7.1]
  def change
    change_table :daily_menus, bulk: true do |t|
      t.jsonb :nutrition_summary_json, default: {}, null: false
      t.jsonb :dietary_guidance_json, default: {}, null: false
      t.jsonb :planning_notes_json, default: {}, null: false
    end

    change_table :daily_menu_items, bulk: true do |t|
      t.integer :servings, default: 1, null: false
      t.integer :repetitions, default: 1, null: false
      t.jsonb :nutrition_json, default: {}, null: false
      t.jsonb :dietary_flags_json, default: [], null: false
      t.text :religious_notes
      t.jsonb :inventory_usage_json, default: [], null: false
    end
  end
end
