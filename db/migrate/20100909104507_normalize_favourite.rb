class NormalizeFavourite < ActiveRecord::Migration
  def self.up
    rename_table(:favourites, :employee_favorites)
  end

  def self.down
    rename_table(:employee_favorites, :favourites)
  end
end
