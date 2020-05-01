class AddColumnLoginDateAndLogoutDateForUserLogs < ActiveRecord::Migration
  def up
    add_column :user_logs, :login_date, :datetime
    add_column :user_logs, :logout_date, :datetime
  end

  def down
    remove_column :user_logs, :login_date
    remove_column :user_logs, :logout_date
  end
end
