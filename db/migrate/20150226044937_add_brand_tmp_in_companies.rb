class AddBrandTmpInCompanies < ActiveRecord::Migration
  def up
  	add_column :companies, :brand_tmp, :string, :default => "Customer"
  end

  def down
  end
end
