class CreateLevelLimits < ActiveRecord::Migration
  def change
    create_table :level_limits do |t|
      t.string :level_type
      t.integer :limit_date
      t.text :description
      t.timestamps
    end
  end
end
