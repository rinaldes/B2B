class AddColumnReceivedEmailForUser < ActiveRecord::Migration
  def up
    add_column :users, :is_received_po, :boolean, :default => false
    add_column :users, :is_received_grn, :boolean, :default => false
    add_column :users, :is_received_grpc, :boolean, :default => false
    add_column :users, :is_received_invoice, :boolean, :default => false
    add_column :users, :is_received_grtn, :boolean, :default => false
  end

  def down
    remove_column :users, :is_received_po
    remove_column :users, :is_received_grn
    remove_column :users, :is_received_grpc
    remove_column :users, :is_received_invoice
    remove_column :users, :is_received_grtn
  end
end
