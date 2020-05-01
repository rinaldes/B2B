class StockSerialLink < ActiveRecord::Base
  belongs_to :purchase_order, :primary_key => "po_number", :foreign_key => "serial_link_code"
  attr_accessible :serial_no, :stock_code, :serial_link_type,
                  :serial_link_code, :link_suffix, :link_seq_no

  def self.get_and_save_grn_serials_from_api(grn)
    begin
      res = OffsetApi.connect_with_query("sseriall", "serial_link_code", grn.po_number)

      unless res.is_a?(Net::HTTPSuccess)
        return OffsetApi.eval_net_http(res)
      end
    rescue => e
      return 3
    end
    result = JSON.parse(res.body)

    if result['data'].blank?
      return true # tetap tampilkan walau datanya kosong
    else
      begin
        ActiveRecord::Base.transaction do
          return false if !StockSerialLink.save_serials_grn(result, grn)
        end
      rescue => e
        ActiveRecord::Rollback
        return false
      end
    end
    return true
  end

  def self.save_serials_grn(params_line, grn)
    params_line["data"].each do |d|
      grn.stock_serial_links.build(
        :serial_no => d["serial_no"],
        :stock_code => d["stock_code"],
        :serial_link_type => d["serial_link_type"],
        :serial_link_code => d["serial_link_code"],
        :link_suffix => d["link_suffix"],
        :link_seq_no => d["link_seq_no"]
      )
    end
    return grn.save
  end
end
