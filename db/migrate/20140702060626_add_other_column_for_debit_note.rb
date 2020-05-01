class AddOtherColumnForDebitNote < ActiveRecord::Migration
  def up
    add_column :debit_notes, :order_number, :string
    add_column :debit_notes, :transaction_date, :date
    add_column :debit_notes, :suffix, :string
    add_column :debit_notes, :trans_type, :string
    add_column :debit_notes, :invoice_date, :date
    add_column :debit_notes, :reference, :string
    add_column :debit_notes, :details, :string
    add_column :debit_notes, :amount, :decimal
    add_column :debit_notes, :due_date, :date
    add_column :debit_notes, :tracking_type, :string
    add_column :debit_notes, :tracking_no, :string
    add_column :debit_notes, :batch, :string
  end

  def down
    remove_column :debit_notes, :order_number
    remove_column :debit_notes, :transaction_date
    remove_column :debit_notes, :suffix
    remove_column :debit_notes, :trans_type
    remove_column :debit_notes, :invoice_date
    remove_column :debit_notes, :reference
    remove_column :debit_notes, :details
    remove_column :debit_notes, :amount
    remove_column :debit_notes, :due_date
    remove_column :debit_notes, :tracking_type
    remove_column :debit_notes, :tracking_no
    remove_column :debit_notes, :batch
  end
end
