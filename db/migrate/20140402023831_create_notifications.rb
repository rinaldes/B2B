class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :state
      t.string :title, limit:100
      t.text :content
      t.references :role
      t.string :notif_type
      t.timestamps
    end
  end
end
