class BarcodeSettingsSupplier < ActiveRecord::Base
  attr_accessible :description, :number, :priority
  attr_protected :supplier_id
  belongs_to :supplier
  validates :priority, :presence => true
  validates_numericality_of :priority, :only_integer => true, :greater_than_or_equal_to => 1

  def self.update_barcode_settings(params)
    barcode_settings = self.where(:supplier_id => params[:id]).order("number ASC")
    begin
      ActiveRecord::Base:transaction do
        barcode_settings.each_with_index do |b,i|
          b.priority = params[:supplier_priority]["#{i}"]
          b.save
        end
      end
    rescue => e
      ActiveRecord::Rollback
    end
  end
end
