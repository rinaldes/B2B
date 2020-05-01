class AddColumnCodeForAddresses < ActiveRecord::Migration
  def up
    add_column :addresses, :accountcode, :string
  end

  def down
    remove_column :addresses, :accountcode
  end
end
