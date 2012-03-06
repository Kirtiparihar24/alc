class AddIndexesForCompliances < ActiveRecord::Migration
  def self.up
    add_index "compliances", ["company_id"], :name => "index_compliances_on_company_id" 
    add_index "compliances", ["create_by_user_id"], :name => "index_compliances_on_create_by_user_id"
    add_index "compliance_types", ["company_id"], :name => "index_compliances_types_on_company_id"
    add_index "compliance_items", ["compliance_id"], :name => "index_compliance_items_on_compliance_id"
    add_index "attachments", ["attachable_type", "attachable_id"], :name => "index_attachments_on_attaachable_type_and_attachable_id"
    add_index "compliance_trails", ["compliance_item_id"], :name => "index_compliance_trails_on_compliance_item_id"
  end

  def self.down
  end
end
