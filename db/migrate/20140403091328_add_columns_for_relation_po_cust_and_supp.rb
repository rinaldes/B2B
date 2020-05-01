class AddColumnsForRelationPoCustAndSupp < ActiveRecord::Migration
  def up
    add_column :purchase_orders, :po_id, :integer
    add_column :purchase_orders, :po_type, :string
  end

  def down
  end
end
