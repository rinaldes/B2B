class CreateLdapSettings < ActiveRecord::Migration
  def change
    create_table :ldap_settings do |t|
      t.integer :company_id
      t.integer :user_id
      t.string :ldap_host
      t.integer :ldap_port
      t.string :ldap_base
      t.string :ldap_method
      t.text :description
      t.timestamps
    end
  end
end
