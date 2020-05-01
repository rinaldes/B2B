class AddColumnToDisputeSettings < ActiveRecord::Migration
  def change
  	add_column :dispute_settings, :transaction_type, :string
  	add_column :dispute_settings, :time_type, :string
  end
end
