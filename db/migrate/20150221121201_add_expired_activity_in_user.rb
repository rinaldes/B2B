class AddExpiredActivityInUser < ActiveRecord::Migration
  def up
  	add_column :users, :expired_activity_at, :datetime
  end

  def down
  	remove_column :users, :expired_activity_at, :datetime
  end
end
