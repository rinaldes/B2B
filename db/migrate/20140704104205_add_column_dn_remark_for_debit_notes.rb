class AddColumnDnRemarkForDebitNotes < ActiveRecord::Migration
  def up
    add_column :debit_notes, :dn_remark, :text
  end

  def down
    remove_column :debit_notes, :dn_remark
  end
end
