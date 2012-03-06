class NormalizeReportFavourite < ActiveRecord::Migration
  def self.up
    # rename to company_favorites
    rename_table(:report_favourites, :company_reports)
  end

  def self.down
    # reset old name
    rename_table(:company_reports, :report_favourites)
  end
end
