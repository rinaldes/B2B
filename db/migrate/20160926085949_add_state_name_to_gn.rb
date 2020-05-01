class AddStateNameToGn < ActiveRecord::Migration
  def change
    add_column :group_notifications, :state, :integer
  end
end
