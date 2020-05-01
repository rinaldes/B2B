class ChangeDetailPaymentToPolymorphic < ActiveRecord::Migration
  def up
    remove_column :payment_details, :debit_note_id
    remove_column :payment_details, :payment_voucher_id
    add_column :payment_details ,:payment_element_id, :integer
    add_column :payment_details, :payment_element_type, :string
  end

  def down
  	add_column :payment_details, :debit_note_id, :integer
  	add_column :payment_details, :payment_voucher_id, :integer
  	remove_column :payment_details ,:payment_element_type
  	remove_column :payment_details, "payment_element_id".to_sym
  end
end
