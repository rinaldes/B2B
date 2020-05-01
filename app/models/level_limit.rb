class LevelLimit < ActiveRecord::Base
  # attr_accessible :title, :body
  attr_accessible :level_type, :limit_date, :description, :email_address_1,:email_address_2,:email_address_3,:email_address_4,:email_address_5
  #belongs_to :supplier
  belongs_to :warehouse
  attr_protected :warehouse_id
  validates :limit_date,
          :presence => true,
          :numericality => true
  validates :email_address_1, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :allow_blank => true}
  validates :email_address_2, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :allow_blank => true}
  validates :email_address_3, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :allow_blank => true}
  validates :email_address_4, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :allow_blank => true}
  validates :email_address_5, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :allow_blank => true}


  def self.save_level_limit(options)
    _arr_return = []
    options.each do |key,val|
      if key == "limit_date"
        options[:limit_date].each do |k,v|
          next if val.blank?
          l_limit = self.find(k)
          if l_limit.level_type == GRN
            _arr_return << l_limit.update_attributes(options[:grn].merge!({:limit_date => v }))
          elsif l_limit.level_type == GRPC
            _arr_return << l_limit.update_attributes(options[:grpc].merge!({:limit_date => v }))
          else
            _arr_return << l_limit.update_attributes(options[:grtn].merge!({:limit_date => v }))
          end
        end
      end
    end
    return _arr_return
  end
end
