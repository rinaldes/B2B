class ChangeColumnApprovedDetailAndApprovedHeader < ActiveRecord::Migration
  def up
    if connection.adapter_name.downcase == 'postgresql'
      connection.execute(%q{
        alter table payment_vouchers
        alter column is_approved
        type integer using is_approved::integer
      })

      connection.execute(%q{
        alter table payment_voucher_details
        alter column is_approved_detail
        type integer using is_approved_detail::integer
      })
    else
      change_column :payment_vouchers, :is_approved, :integer
      change_column :payment_voucher_details, :is_approved_detail, :integer
    end
  end

  def down
  end
end
