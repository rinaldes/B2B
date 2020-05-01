class CreateDebitNoteLines < ActiveRecord::Migration
  def change
    create_table :debit_note_lines do |t|
      t.timestamp :transaction_date
      t.string :branch
      t.string :tracking_no
      t.string :bo_suffix
      t.string :trans_type
      t.timestamp :invoice
      t.string :ref
      t.string :detail
      t.integer :amount
      t.decimal :batch


      t.timestamps null: false
    end
  end
end
