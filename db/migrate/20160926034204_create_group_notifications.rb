class CreateGroupNotifications < ActiveRecord::Migration
  def change
    create_table :group_notifications do |t|
      t.integer :notification_id
      t.integer :receipant_id
      t.timestamps
    end
  end
end
