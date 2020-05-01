class CreateUserLogs < ActiveRecord::Migration
  def change
    create_table :user_logs do |t|
      t.integer :user_id
      t.integer :transaction_id
      t.string :model_name
      t.string :log_type
      t.string :event
      t.timestamps
    end
  end
end
