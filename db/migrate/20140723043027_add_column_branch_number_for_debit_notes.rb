class AddColumnBranchNumberForDebitNotes < ActiveRecord::Migration
  def up
    add_column :debit_notes, :branch_number, :string
  end

  def down
    remove_column :debit_notes, :branch_number
  end
end
