class UserLog < ActiveRecord::Base
   attr_accessible :transaction_type, :event, :log_type, :login_date, :logout_date
   attr_protected :user_id, :log_id
   belongs_to :user
   belongs_to :log, :polymorphic => true
   scope :history_login_activity, proc { where("log_id is NULL") }
   scope :history_transaction_activity, proc { where("log_id is NOT NULL") }
   paginates_per PER_PAGE
  def self.filter(options, user)
    unless options[:search].blank?
      resp = ""
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'username'
          unless options[:search][:detail].blank?
            resp = joins(:user).where("users.login ilike ?", "%#{options[:search][:detail].strip}%")
          else
            resp = scoped
          end
        when 'transaction number / voucher'
          if options[:search][:field_2].present?
            arr = []
            case options[:search][:field_2]
              when "#{PO}","#{GRN}","#{GRPC}","#{INV}","#{EPR}"
                if options[:search][:detail].blank?
                  resp = where("user_logs.transaction_type ilike ?", "%#{options[:search][:field_2]}%")
                else
                  where("user_logs.transaction_type ilike ?", "%#{options[:search][:field_2]}%").collect{|logUser|
                    next if logUser.log.blank?
                    arr << logUser.id if options[:search][:field_2] == PO && logUser.log.po_number == options[:search][:detail]
                    arr << logUser.id if options[:search][:field_2] == GRN && logUser.log.grn_number == options[:search][:detail]
                    arr << logUser.id if options[:search][:field_2] == GRPC && logUser.log.grpc_number == options[:search][:detail]
                    arr << logUser.id if options[:search][:field_2] == INV && logUser.log.invoice_number == options[:search][:detail]
                    arr << logUser.id if options[:search][:field_2] == EPR && logUser.log.purchase_order.po_number == options[:search][:detail]
                  }
                  resp = scoped.where(:id => arr)
                end
              when "#{DN}"
                if options[:search][:detail].blank?
                  resp = where("user_logs.transaction_type ilike ?","#{DN}")
                else
                  where("user_logs.transaction_type ilike ?","%#{DN}%").collect{|logUser|
                    arr << logUser.id if logUser.log.order_number == options[:search][:detail]
                  }
                  resp = scoped.where(:id => arr)
                end
              when "#{PV}"
                if options[:search][:detail].blank?
                  resp = where("user_logs.transaction_type ilike ? ", "%#{PV}%")
                else
                  where("user_logs.transaction_type ilike ?","%#{PV}%").collect{|logUser|
                    arr << logUser.id if logUser.log.voucher == options[:search][:detail]
                  }
                  resp = scoped.where(:id => arr)
                end
              when "#{GRTN}"
                if options[:search][:detail].blank?
                  resp = where("user_logs.transaction_type ilike ?", "%Return Process%")
                else
                  where("user_logs.transaction_type ilike ?","%Return Process%").collect{|logUser|
                    arr << logUser.id if logUser.log.rp_number == options[:search][:detail]
                  }
                  resp = scoped.where(:id => arr)
                end
              else
                return scoped
            end

          else
            return scoped
          end
        else
          return scoped
        end
      else
        return scoped
      end
    else
      return scoped
    end
  return resp
  end
end
