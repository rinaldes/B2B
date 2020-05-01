class DebitNoteLine < ActiveRecord::Base
  belongs_to :debit_note
  attr_accessible :transaction_date, :branch, :tracking_no, :bo_suffix, :trans_type,
                  :invoice, :ref, :detail, :amount, :batch, :sol_line_seq,
                  :stock_code, :stk_unit_desc, :sol_tax_rate, :sol_item_price,
                  :sol_shipped_qty, :shipped_amount, :remark, :dispute_qty, :is_disputed, :debit_note_id

  def prep_json
    val = []
    val << "'b2b_so_order_no': #{debit_note.order_number}"
    val << "'b2b_sol_line_seq': #{sol_line_seq}"
    val << "'b2b_stock_code': '#{stock_code}'"
    val << "'b2b_stk_unit_desc': '#{stk_unit_desc}'"
    val << "'b2b_sol_tax_rate': #{sol_tax_rate}"
    val << "'b2b_sol_item_price': #{sol_item_price}"
    val << "'b2b_sol_shipped_qty': #{sol_shipped_qty}"
    val << "'b2b_shipped_amount': #{shipped_amount}"

    return "{#{val.join(",").gsub!("'", '"')}}"
  end

  def order_total
    shipped = dispute_qty || sol_shipped_qty
    shipped*sol_item_price+sol_tax_rate*sol_item_price/100*shipped
  end

  def product
    Product.find_by_code(stock_code.squish)
  end
end
