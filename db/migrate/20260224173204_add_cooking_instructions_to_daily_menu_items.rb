class AddCookingInstructionsToDailyMenuItems < ActiveRecord::Migration[7.1]
  def change
    add_column :daily_menu_items, :cooking_instructions_json, :jsonb, default: {}, null: false
  end
end
