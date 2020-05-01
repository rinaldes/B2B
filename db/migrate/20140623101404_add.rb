class Add < ActiveRecord::Migration
  def up
  	add_column :returned_processes, :invoice_number, :string, :limit=>100
  end

  def down
  	remove_column :returned_processes, :invoice_number
  end
end
