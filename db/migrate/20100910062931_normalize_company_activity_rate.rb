class NormalizeCompanyActivityRate < ActiveRecord::Migration
  def self.up
    # rename column, activity_id is comming from company_lookup
    rename_column(:company_activity_rates, :activity_id, :activity_type_id)
  end

  def self.down
    rename_column(:company_activity_rates, :activity_type_id, :activity_id)
  end
end
