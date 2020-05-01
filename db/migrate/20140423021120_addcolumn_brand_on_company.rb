class AddcolumnBrandOnCompany < ActiveRecord::Migration
  def up
  	add_column :companies, :brand, :string
  	add_column :addresses, :website, :string
  	add_column :addresses, :office_address, :string
  	remove_column :addresses, :company_id
  end

  def down
  	remove_column :companies, :brand, :string
  	remove_column :addresses, :website, :string
  	remove_column :addresses, :office_address, :string
    add_column :addresses, :company_id, :integer
  end
end
