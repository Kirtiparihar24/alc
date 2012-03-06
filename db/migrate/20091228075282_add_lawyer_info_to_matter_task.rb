class AddLawyerInfoToMatterTask < ActiveRecord::Migration
  def self.up
    add_column :matter_tasks, :lawyer_name, :string
    add_column :matter_tasks, :lawyer_email, :string
  end

  def self.down
    remove_column :matter_tasks, :lawyer_email
    remove_column :matter_tasks, :lawyer_name
  end
end
