class AddIsReceivedAsnToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_received_asn, :boolean
  end
end
