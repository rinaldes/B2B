class AddColumnRevisionTo < ActiveRecord::Migration
  def up
    add_column :purchase_orders, :revision_to, :integer
    add_column :returned_processes, :revision_to, :integer
  end

  def down
    remove_column :purchase_orders, :revision_to, :integer
    remove_column :returned_processes, :revision_to, :integer
  end
end
