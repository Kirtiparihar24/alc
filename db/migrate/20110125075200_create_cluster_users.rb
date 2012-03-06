class CreateClusterUsers < ActiveRecord::Migration
  def self.up
    create_table :cluster_users do |t|


      t.integer :user_id
      t.integer :cluster_id
      t.timestamps
    end
  end

  def self.down
    drop_table :cluster_users
  end
end
