class AddColumnCompanyIdForTypeOfUsers < ActiveRecord::Migration
  def up
    add_column :type_of_users, :company_id, :integer
  end

  def down
    remove_column :type_of_users, :company_id
  end
end
