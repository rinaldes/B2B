class ChangeColumnTransactionIdForUserLogs < ActiveRecord::Migration
  def up
    rename_column :user_logs, :transaction_id, :log_id
    rename_column :user_logs, :log_type, :transaction_type
    rename_column :user_logs, :model_name, :log_type
  end

  def down
    rename_column :user_logs, :log_id, :transaction_id
  end
end
