class AddColumnSupplierIdAndCustomerIdAndCompanyIdForAddresses < ActiveRecord::Migration
  def up
    remove_column :addresses, :company
    add_column :addresses, :company_id, :integer
    add_column :addresses, :customer_id, :integer
    add_column :addresses, :supplier_id, :integer
  end

  def down
  end
end
