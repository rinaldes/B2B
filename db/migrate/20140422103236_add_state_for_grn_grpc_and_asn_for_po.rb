class AddStateForGrnGrpcAndAsnForPo < ActiveRecord::Migration
  def up
  	add_column :purchase_orders, :grn_state, :integer
  	add_column :purchase_orders, :grpc_state, :integer
  	add_column :purchase_orders, :asn_state, :integer
  end

  def down
  end
end
