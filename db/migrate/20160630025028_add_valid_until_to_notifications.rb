class AddValidUntilToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :valid_until, :datetime
  end
end
