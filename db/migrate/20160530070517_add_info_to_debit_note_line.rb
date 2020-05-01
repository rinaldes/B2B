class AddInfoToDebitNoteLine < ActiveRecord::Migration
  def up
    add_column :debit_note_lines, :sol_line_seq, :decimal
    add_column :debit_note_lines, :stock_code, :string
    add_column :debit_note_lines, :stk_unit_desc, :string
    add_column :debit_note_lines, :sol_tax_rate, :decimal
    add_column :debit_note_lines, :sol_item_price, :decimal
    add_column :debit_note_lines, :sol_shipped_qty, :decimal
    add_column :debit_note_lines, :shipped_amount, :decimal
  end

  def down
    remove_column :debit_note_lines, :sol_line_seq
    remove_column :debit_note_lines, :stock_code
    remove_column :debit_note_lines, :stk_unit_desc
    remove_column :debit_note_lines, :sol_tax_rate
    remove_column :debit_note_lines, :sol_item_price
    remove_column :debit_note_lines, :sol_shipped_qty
    remove_column :debit_note_lines, :shipped_amount
  end
end
