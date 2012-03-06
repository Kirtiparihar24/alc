class AddFieldsToMatterTermconditions < ActiveRecord::Migration
  def self.up
    add_column :matter_termconditions, :billing_by, :string, :limit => 64
    add_column :matter_termconditions, :retainer_amount, :string, :limit => 64
    add_column :matter_termconditions, :not_to_exceed_amount, :string, :limit => 64
    add_column :matter_termconditions, :min_trigger_amount, :string, :limit => 64
    add_column :matter_termconditions, :fixed_rate_amount, :string, :limit => 64
    add_column :matter_termconditions, :additional_details, :string
  end

  def self.down
    remove_column :matter_termconditions, :billing_by
    remove_column :matter_termconditions, :retainer_amount
    remove_column :matter_termconditions, :not_to_exceed_amount
    remove_column :matter_termconditions, :min_trigger_amount
    remove_column :matter_termconditions, :fixed_rate_amount
    remove_column :matter_termconditions, :additional_details
  end
end
