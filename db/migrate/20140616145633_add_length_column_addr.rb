class AddLengthColumnAddr < ActiveRecord::Migration
  def up
  	change_column :addresses, :street, :string, :limit=>255
  	change_column :addresses, :suburb, :string, :limit=>255
  	change_column :addresses, :country_code, :string, :limit=>255
  	change_column :addresses, :postcode, :string, :limit=>255
  	change_column :addresses, :phone, :string, :limit=>255
  	change_column :addresses, :fax_no, :string, :limit=>255
  	change_column :addresses, :mobile_phone, :string, :limit=>255
  	change_column :addresses, :country, :string, :limit=>255
  end

  def down
  	change_column :addresses, :street, :string, :limit=>45
  	change_column :addresses, :suburb, :string, :limit=>45
  	change_column :addresses, :country_code, :string, :limit=>15
  	change_column :addresses, :postcode, :string, :limit=>25
  	change_column :addresses, :phone, :string, :limit=>45
  	change_column :addresses, :fax_no, :string, :limit=>45
  	change_column :addresses, :mobile_phone, :string, :limit=>45
    change_column :addresses, :country, :string, :limit=>45
  end
end
