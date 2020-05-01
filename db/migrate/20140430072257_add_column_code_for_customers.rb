class AddColumnCodeForCustomers < ActiveRecord::Migration
  def up
    add_column :customers, :code, :string
  end

  def down
    remove_column :customers, :code
  end
end
