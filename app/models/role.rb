class Role < ActiveRecord::Base
  has_and_belongs_to_many :users, :join_table => :users_roles
  has_and_belongs_to_many :features, :join_table => :features_roles
  belongs_to :parent, :class_name => "Role"
  has_many :roles, :foreign_key => "parent_id"
  has_many :notifications
  scopify
  # attr_accessible :title, :body
  attr_accessible :name, :group_name, :group_flag
  attr_protected :feature_ids, :parent_id
  attr_accessor :group_name
  scope :role_group, proc { |status| where('parent_id' => nil).where("name = 'supplier' or name = 'customer'")}
  scope :customer, proc { |re| where('name' => 'customer') }
  scope :supplier, proc { |rs| where('name' => 'supplier') }
  #scope :default_user, proc { |rs| where('name' => 'default_user') }
  #scope :supplier_child, proc { |sc| where("parent_id = (SELECT id FROM roles WHERE name = 'supplier')") }
  scope :only_super_admin, proc {|r| where(:group_flag => true)}
  before_destroy :check_role
  #validation
  validates :name, presence: {message: "Role name can't be blank", allow_blank: false, allow_nil: false},:allow_blank => true, uniqueness: {:scope => :parent_id}, length:{minimum: 3, message: "that is not even a name"}
  #validates :parent_id, presence: {message: "Please choose role group ",allow_blank: false, allow_nil: false}, :allow_blank=>true
  #for pagination
  paginates_per PER_PAGE
  max_paginates_per 100

  def self.only_admin_group(from)
    parent_role = self.find_by_name("#{from}")
    return self.find(:all, :conditions => ["roles.parent_id = ?", parent_role.id])
  end

  def self.search(options)
    unless options[:search].blank?
      if options[:search][:field].present?
        case options[:search][:field].downcase
        when 'name'
          where("name ilike ?", "%#{options[:search][:detail]}%")
          when 'group'
            company = Company.find_by_brand_tmp(options[:search][:detail])
            unless company.blank?
              parent = Role.find_by_name("customer")
              if !parent.nil?
                where("id = ? OR parent_id = ?", parent.id,parent.id)
              end
            else
                parent = Role.find_by_name("#{options[:search][:detail]}")
                if !parent.nil?
                  where("id = ? OR parent_id = ?", parent.id,parent.id)
                else
                  where("parent_id = 0")
                end
            end
        end
      else
         where("name ilike ?", "%#{options[:search][:detail]}%")
      end
    else
      scoped
    end
  end

  def save_features(params)
    flag = ''
    begin
      ActiveRecord::Base.transaction do
        if self.features.delete_all
          params[:role][:feature_ids].each do |feature|
            self.features << Feature.find(feature)
          end
        end
      end
      return flag = true
    rescue => e
      ActiveRecord::Rollback
      flag=false
      return flag
    end
  end

  def self.set_role(params, user)
    role=Role.new(params[:role])
    unless params[:role][:group_name].blank?
      check = Role.find("#{params[:role][:group_name].downcase}")
      if check.blank?
        role.errors.add(:group_name, "Group not found")
        return role
      else
        role.parent_id = check.id
      end
    end
    if user.has_role? :superadmin
      role.group_flag = true
    end

    role.save
    return role
  end
  def update_role(params)
    params[:role].each do |k,v|
      case k.to_s
        when "name"
          self.name = "#{v}"
      end
    end
    unless params[:role][:group_name].blank?
      if params[:role][:group_name] == "No Group"
        self.parent_id = nil
        self.save
        return true
      else
        check = Role.find("#{params[:role][:group_name].downcase}")
        if check
          self.parent_id = check.id
          if self.save
            return true
          else
            return false
          end
        else
          self.errors.add(:group_name, "Group not found")
          return false
        end
      end
    end
    self.save
    return true
  end

  def check_role
    false if self.present?
  end

end