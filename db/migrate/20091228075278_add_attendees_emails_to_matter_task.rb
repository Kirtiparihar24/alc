class AddAttendeesEmailsToMatterTask < ActiveRecord::Migration
  def self.up
    add_column :matter_tasks, :attendees_emails, :text
  end

  def self.down
    remove_column :matter_tasks, :attendees_emails
  end
end
