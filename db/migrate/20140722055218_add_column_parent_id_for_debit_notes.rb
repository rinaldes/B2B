class AddColumnParentIdForDebitNotes < ActiveRecord::Migration
  def up
    add_column :debit_notes, :parent_id, :integer
  end

  def down
    remove_column :debit_notes, :parent_id
  end
end
