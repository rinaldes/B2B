class AddDisputeQtyToDnl < ActiveRecord::Migration
  def change
    add_column :debit_note_lines, :dispute_qty, :decimal
    add_column :debit_note_lines, :is_disputed, :boolean
    add_column :debit_note_lines, :remark, :text
  end
end
