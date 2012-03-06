class AddFavoriteToManageDashboards < ActiveRecord::Migration
  def self.up
    add_column :manage_dashboards, :is_fav, :boolean
    add_column :manage_dashboards, :fav_title, :string
  end

  def self.down
    remove_column :manage_dashboards, :is_fav
    remove_column :manage_dashboards, :fav_title
  end
end
