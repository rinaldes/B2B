class AddColumnOnAddressTable < ActiveRecord::Migration
  def up
  	add_column :addresses, :company, :string,:limit=>45
  	add_column :addresses, :street, :string,:limit=>45
  	add_column :addresses, :suburb, :string, :limit=>45
  	add_column :addresses, :country, :string, :limit=>45
  	add_column :addresses, :postcode, :string, :limit=>25
  	add_column :addresses, :country_code, :string, :limit=>15
  	add_column :addresses, :phone, :string, :limit=>45
  	add_column :addresses, :mobile_phone, :string, :limit=>45
  	add_column :addresses, :fax_no, :string, :limit=>45
  	add_column :addresses, :company_id, :integer
  	add_column :addresses, :tax_province_code, :string
  	add_column :addresses, :ausbar_code, :string
  	
  end
  def down
  end
end
