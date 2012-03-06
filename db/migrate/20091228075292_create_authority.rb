class CreateAuthority < ActiveRecord::Migration
  def self.up
    create_table :authorities do |t|
      t.string 'name' , :limit=>64
      t.text 'description'
      t.timestamps
    end
  end

  def self.down
    drop_table :authorities
  end

end
