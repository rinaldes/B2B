class CreateUserLevelDisputes < ActiveRecord::Migration
  def change
    create_table :user_level_disputes do |t|
      t.integer :user_id
      t.integer :level
      t.integer :dispute_setting_id
      t.timestamps
    end
  end
end
