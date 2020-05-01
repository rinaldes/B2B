class CreateDisputeSettings < ActiveRecord::Migration
  def change
    create_table :dispute_settings do |t|
      t.integer :max_count
      t.string :counter_type #day/hour
      t.integer :counter
      t.timestamps
    end
  end
end
