class CreatePriorityTypes < ActiveRecord::Migration
 #Priorities for livians
 #Preferred (Priority 1), High (Priority 2), Medium (Priority 3) or Low (Priority 4)
 #Default Priority (Null 0)
  def self.up
    execute "INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('PriorityType','0',1,'None');
             INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('PriorityType','1',1,'Preferred');
             INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('PriorityType','2',1,'High');
             INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('PriorityType','3',1,'Medium');
             INSERT INTO company_lookups (type,lvalue,company_id,alvalue) values('PriorityType','4',1,'Low');"
  end

  def self.down
    execute "Delete from company_lookups where type='PriorityType'"
  end
end
