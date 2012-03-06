class Link < ActiveRecord::Base
  acts_as_paranoid
 belongs_to :mapable, :polymorphic => true
 belongs_to :category, :class_name => "DocumentType", :foreign_key => :category_id
 belongs_to :company
 #belongs_to :sub_category, :class_name => "DocumentSubCategory"
 belongs_to  :created_by, :class_name => "User", :foreign_key => :created_by_employee_user_id
 belongs_to :folder
 validates_presence_of :url,  :message => 'Link cannot be blank'
 validates_presence_of :name, :message => "Link Name can't be blank"

 named_scope :root_links, {:conditions => ['folder_id is null']}
 # Return only the links that have given category.
 named_scope :has_category, lambda {|kat|
   if kat.to_i > 0
     {:conditions => ["category_id = #{kat}"]}   
   end
 }

 attr_accessor :file, :tag_array
 acts_as_taggable
 define_index do
    set_property :delta => true
    indexes :name, :as => :link_name, :prefixes => true
    indexes :mapable_type, :as => :link_mapable_type, :prefixes => true
    indexes :description, :as => :link_description, :prefixes => true
    indexes [created_by.first_name, created_by.last_name], :as => :link_creator_name, :prefixes => true
    indexes category(:lvalue), :as => :link_category, :prefixes => true
    indexes tags(:name), :as=>:tag_name, :prefixes => true
    has :mapable_id, :as => :link_mapable_id
    has :created_by_employee_user_id, :created_at, :updated_at, :company_id
    has :created_at, :as => :link_created_date
    has :updated_at, :as => :link_updated_date

    where "links.deleted_at is null"
  end

  sphinx_scope(:current_company) { |company_id|
    {:with => {:company_id => company_id}}
  }

end

# == Schema Information
#
# Table name: links
#
#  id                          :integer         not null, primary key
#  company_id                  :integer
#  description                 :text
#  name                        :string(255)
#  mapable_id                  :integer
#  mapable_type                :string(255)
#  category_id                 :integer
#  deleted_at                  :datetime
#  permanent_deleted_at        :datetime
#  url                         :text
#  created_by_user_id          :integer
#  created_by_employee_user_id :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  delta                       :boolean         default(TRUE)
#  sub_category_id             :integer
#  folder_id                   :integer
#

