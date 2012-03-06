class CreateClusters < ActiveRecord::Migration
  def self.up
    create_table :clusters do |t|
      t.string 'cluster_no',:limit=>15
      t.text 'description'
      #t.timestamps
    end
  end

  def self.down
    drop_table :clusters
  end
end
