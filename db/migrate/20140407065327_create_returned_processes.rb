class CreateReturnedProcesses < ActiveRecord::Migration
  def change
    create_table :returned_processes do |t|
      t.integer :rp_number
      t.date :rp_date
      t.decimal :grand_total
      t.integer :purchase_order_id
      t.integer :user_id
      t.integer :state
      t.timestamps
    end
  end
end
