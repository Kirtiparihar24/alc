class ChangeParalegalInLookups < ActiveRecord::Migration
  def self.up
    execute "update lookups set lvalue = 'Paralegal' where type = 'TeamRoles' AND lvalue = 'Para Legal'"
  end

  def self.down
    execute "update lookups set lvalue = 'Para Legal' where type = 'TeamRoles' AND lvalue = 'Paralegal'"
  end
end
