class CreateTotalPerLineForDetailReturnProcess < ActiveRecord::Migration
  def up
    add_column :returned_process_details, :total_price_per_line, :decimal, :precision=>10, :scale=>2
  end

  def down
    remove_column :returned_process_details, :total_price_per_line
  end
end
