class CreateComplianceTypes < ActiveRecord::Migration
  def self.up
    create_table :compliance_types do |t|
      t.integer 'company_id'
      t.integer 'parent_id'      
      t.string 'lvalue', :limit=>'128'            
      t.timestamps
    end
  end

  def self.down
    drop_table :compliance_types
  end
end
