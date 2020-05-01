class Addcolumnforsuppliers < ActiveRecord::Migration
  def up
  	add_column :suppliers, :account_code, :string,:limit=>45
    add_column :suppliers, :pay_to_code, :string, :limit=>45
    add_column :suppliers, :shortname, :string, :limit=>45
  end

  def down
  end
end
