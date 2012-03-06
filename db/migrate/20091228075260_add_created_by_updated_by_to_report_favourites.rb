class AddCreatedByUpdatedByToReportFavourites < ActiveRecord::Migration
  def self.up
    add_column :report_favourites, :created_by_user_id, :integer
    add_column :report_favourites, :updated_by_user_id, :integer
  end

  def self.down
    remove_column :report_favourites, :updated_by_user_id
    remove_column :report_favourites, :created_by_user_id
  end
end
