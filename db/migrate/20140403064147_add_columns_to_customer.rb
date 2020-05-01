class AddColumnsToCustomer < ActiveRecord::Migration
  def change
  	add_column :customers, :name, :string, :limit=>100
  	add_column :customers, :email, :string, :limit=>100
  	add_column :customers,:customer_type, :string, :limit=>45
  end
end
