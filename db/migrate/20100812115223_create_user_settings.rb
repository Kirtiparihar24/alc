class CreateUserSettings < ActiveRecord::Migration
  def self.up
    create_table :user_settings do |t|
      t.integer :user_id
      t.string :setting_type
      t.string :setting_value
      t.integer :company_id

      t.timestamps
    end

    @usr = User.find(:all).find_all{|e| e.role?(:lawyer)}
    @usr.each do |u|
       UserSetting.create(:user_id => u.id, :setting_type => 'upcoming', :setting_value => '7', :company_id => u.company_id)
    end
    
  end

  def self.down
    drop_table :user_settings
  end
end
