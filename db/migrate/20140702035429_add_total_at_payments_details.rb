class AddTotalAtPaymentsDetails < ActiveRecord::Migration
  def up
    add_column :payment_details, :total, :decimal, :precision=> 12, :scale=>2
  end

  def down
  	remove_column :payment_details, :total
  end
end
