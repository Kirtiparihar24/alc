class AlterCompliancesForReferenceAndDefaults < ActiveRecord::Migration
  def self.up
    add_column :compliances, :reference, :text
    add_column :compliances, :reminder_start_date, :date
    add_column :compliances, :time_before_due, :string
    add_column :compliances, :reminder_frequency, :string
  end

  def self.down
    remove_column :compliances, :reference
    remove_column :compliances, :reminder_start_date
    remove_column :compliances, :time_before_due
    remove_column :compliances, :reminder_frequency
  end
end
