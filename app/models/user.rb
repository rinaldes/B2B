class User < ActiveRecord::Base
  rolify
  include CredentialLdap
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :timeoutable#, :expirable#, :session_limitable #, :validatable
  attr_accessor :desc, :empo_supplier, :group_user

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me, :username,
                  :login, :has_signed_in, :first_name, :last_name, :is_activated, :user_type, :desc,
                  :empo_supplier
  attr_protected :warehouse_id, :supplier_id, :type_of_user_id

  #validate create user
  validates :username, presence: {:message => "Sorry, Username can't be blank.", on: :create}, uniqueness: {:message => 'Sorry, Username has been existed.', on: :create}
  validates :password, presence: {:message => "Sorry, Password can't be blank.",allow_blank: false, allow_nil: false}, on: :create
  validates_presence_of :password_confirmation, :if => :password_changed?, on: :create
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, on: :create, :allow_blank => true}, presence: {:message => "Sorry, Email can't be blank.", on: :create}, uniqueness: {:message => 'Sorry, Email has been existed.', on: :create}
  validates :desc, presence: { :message => "Please choose user come from. Customer or Supplier" }, on: :create, :if => :valid_supplier_or_empo?
  validates :type_of_user_id, presence: {:message => "Please choose the Group User"}, on: :create
  scope :user_is_active, proc { |status| where('is_activated' => true) }

  paginates_per PER_PAGE
  max_paginates_per 100

  belongs_to :supplier
  belongs_to :warehouse
  has_many :ldap_settings
  has_many :purchase_orders
  belongs_to :type_of_user
  has_many :deliver_banks
  has_many :user_logs
  has_many :debit_notes
  has_many :payment_vouchers
  has_many :early_payment_requests
  has_many :users_features
  has_many :features, through: :users_features
  has_many :group_notifications, foreign_key: :receipant_id
  has_many :notifications, through: :group_notifications
  #author : Leonardo
  #desc : check login with LDAP is existed or not
  def self.check_is_ldap_user(params, ldap_config, status_ldap)
    _arr_attr_from_ldap = []
    if params[:user]
      if status_ldap
        ldap = CredentialLdap.setup_ldap(params, ldap_config)
        if ldap.present?
          if ldap.bind
            filter = Net::LDAP::Filter.eq("cn", "#{params[:user][:login]}")
            treebase = "#{ldap_config.ldap_base}"
            ldap.search(:base => treebase, :filter => filter) do |entry|
              entry.each do |attribute, values|
                _arr_attr_from_ldap << attribute
              end
              if self.is_existed_from_db?(params[:user][:login]).blank?
                user = self.new
                register_from_ldap = user.save_register_user_from_ldap(entry, _arr_attr_from_ldap, params)
                return register_from_ldap
              else
                return false
              end
            end
          else
            return false
          end
        else
          return false
        end
      else
        return false
      end
    end
  end

  #author : leonardo
  #desc : saving LDAP user to database
  def save_register_user_from_ldap(entry, _arr_attr_from_ldap, params)
    flag = false
    user_name = entry.cn.join().gsub(" ","")
    self.email = (entry.mail.join() if _arr_attr_from_ldap.include?(:mail))
    self.username = (user_name if _arr_attr_from_ldap.include?(:cn))
    self.login = (user_name if _arr_attr_from_ldap.include?(:cn))
    self.first_name = (entry.givenname.join() if _arr_attr_from_ldap.include?(:givenname))
    self.last_name = (entry.sn.join() if _arr_attr_from_ldap.include?(:sn))
    self.is_activated = true
    self.password = params[:user][:password]
    self.password_confirmation = params[:user][:password]
    self.user_type = "ldap"
    self.type_of_user_id = TypeOfUser.where("parent_id = (SELECT id FROM type_of_users WHERE description = 'Customer')").first.try(:id)
    self.warehouse_id = Warehouse.find_by_warehouse_name("Gudang Default").id
    if self.valid? && self.save
      group = self.warehouse.group.set_feature("warehouse")
      self.add_role(:customer_admin_group)
      flag = self
    end
    return flag
  end

  #author : Leonardo
  #desc: check user for DB b2b
  def self.is_existed_from_db?(login)
    return self.where("login = ? ", '#{login}')
  end

  def save_features(params, current_user)
    flag = ''
    #begin
      #ActiveRecord::Base.transaction do
        if self.features.delete_all
          params[:user][:feature_ids].each do |feature|
            self.features << Feature.find(feature)
          end
        end
      #end
      return flag = true
    #rescue => e
      ActiveRecord::Rollback
      flag=false
      return flag
    #end
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions).where(["lower(username) = :value", { :value => login.strip.downcase }]).user_is_active.first
  end

  def is_supplier_admin_group
    has_role?("supplier_admin_group")
  end

  def is_customer_admin_group
    has_role?("customer_admin_group")
  end

  #author: leonardo
  #desc: create user
  def save_register_user(params)
    flag = false
    register = params[:user]
    self.login = register[:username]
    self.type_of_user_id = params[:group_user]
    if params[:warehouse].present?
      self.warehouse_id = params[:warehouse][:warehouse_id]
    else
      self.supplier_id = params[:supplier][:supplier_id]
    end

    if self.save
      unless self.has_role? :superadmin
        if self.supplier.present?
          self.supplier.group.set_feature("supplier", self, params)
          flag = true
        else
          self.warehouse.group.set_feature("warehouse",self, params)
          flag = true
        end
      end
    end
    return flag
  end

  #author: chaerul
  #desc: update user
  def update_user(params)
   self.type_of_user_id = params[:group_user]
   if params[:warehouse].present?
    self.warehouse_id = params[:warehouse][:warehouse_id]
    self.is_received_po = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:user][:is_received_po])
    self.is_received_grn = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:user][:is_received_grn])
    self.is_received_grpc = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:user][:is_received_grpc])
    self.is_received_invoice = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:user][:is_received_invoice])
    self.is_received_grtn = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:user][:is_received_grtn])
    self.is_received_early_payment_request = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:user][:is_received_early_payment_request])
    self.is_received_debit_note = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:user][:is_received_debit_note])
    self.is_received_payment_voucher = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:user][:is_received_payment_voucher])
    self.is_received_payment_process = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(params[:user][:is_received_payment_process])
   else
    self.supplier_id = params[:supplier][:supplier_id]
   end
    self.save
  end

  #desc: for change password an user
  def password_changed?
    if password.blank?
      errors.add :password_confirmation, "You must confirm your password"
    elsif password.present? and not password.match(password_confirmation)
      errors.add :password_confirmation, "Password confirmation should be same with password"
    end

  end

  def check_password?(params)
    if !params[:password].blank? || !params[:password_confirmation].blank?
      unless params[:password] == params[:password_confirmation]
        self.errors.add(:password_confirmation, "confirmation password does not match the password, try again")
        return false
      else
        return true
      end
      if params[:password].blank?
        self.errors.add(:password, "Can't be blank")
      elsif params[:password_confirmation].blank?
        self.errors.add(:password_confirmation, "Can't be blank")
      end
      return false
    else
      self.errors.add(:password, "Can't be blank")
      return false
    end
  end

  #author: leonardo
  #desc: searching user based on category
  def self.search(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'email'
          where("email ilike ?", "%#{options[:search][:detail]}%")
          when 'username'
            where("username ilike ?", "%#{options[:search][:detail]}%")
            when 'role'
              joins(:roles).where("roles.name ilike ?", "%#{options[:search][:detail]}%")
              when 'name'
                where("first_name ilike ? OR last_name ilike ?","%#{options[:search][:detail]}%", "%#{options[:search][:detail]}%")
        end
      else
         where("username ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      scoped
    end
  end

  #author: Leonardo
  #desc: change activation user
  def change_activation(user)
    text = ""
    unless user.id == self.id
      if self.is_activated
        self.is_activated = false
        text = "The user is now Inactive"
      else
        self.is_activated = true
        text = "The user has been Activated"
      end
      return_status = self.save!
    else
      text = "Sorry, the user is currently in use. Please logout first."
      return_status = false
    end
    return return_status, text
  end

  def is_supplier?
    unless self.empo_supplier.blank?
      self.empo_supplier.downcase == "supplier" && self.desc.blank?
    end
  end

  def valid_supplier_or_empo?
    unless self.roles.collect(&:name).include?("superadmin")
      if self.supplier_id.blank? && self.warehouse_id.blank?
        errors.add(:desc, "You must select where is user coming from")
      end
      if !self.supplier_id.blank?
        check = Supplier.select("id").find_by_id(self.supplier_id)
        if check.blank?
          errors.add(:desc, "Error, supplier was not found")
          return true
        else
          return false
        end
      elsif !self.warehouse_id.blank?
        check = Warehouse.select("id").find_by_id(self.warehouse_id)
        if check.blank?
          errors.add(:desc, "Error, warehouse was not found")
          return true
        else
           return false
        end
      end
    end
  end
end
