class CreateTimeimports < ActiveRecord::Migration
  def self.up
    create_table :timeimports do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :timeimports
  end
end
