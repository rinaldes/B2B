class AddDebitNoteIdToDnl < ActiveRecord::Migration
  def change
    add_column :debit_note_lines, :debit_note_id, :integer
  end
end
