class Added5ColumnEmailAddressForLevelLimits < ActiveRecord::Migration
  def up
    add_column :level_limits, :email_address_1, :string
    add_column :level_limits, :email_address_2, :string
    add_column :level_limits, :email_address_3, :string
    add_column :level_limits, :email_address_4, :string
    add_column :level_limits, :email_address_5, :string
  end

  def down
    remove_column :level_limits, :email_address_1
    remove_column :level_limits, :email_address_2
    remove_column :level_limits, :email_address_3
    remove_column :level_limits, :email_address_4
    remove_column :level_limits, :email_address_5
  end
end
