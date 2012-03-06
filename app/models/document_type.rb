class DocumentType < CompanyLookup
  belongs_to :company
  has_many :documents, :foreign_key => :doc_type_id
  #has_many :documents, :foreign_key => :category_id
  has_many :links ,:foreign_key => :category_id
  validates_presence_of :alvalue ,:message =>"Document type can't be blank"

  def self.add_document_type(company, params)
    document_type = DocumentType.new(params[:document_type].merge(:lvalue=>params[:document_type][:alvalue]))
    if document_type.valid? && document_type.errors.empty?
      company.document_types << document_type
    end

    document_type
  end
  
end

# == Schema Information
#
# Table name: company_lookups
#
#  id                   :integer         not null, primary key
#  type                 :string(255)
#  lvalue               :string(255)
#  company_id           :integer         default(1)
#  created_at           :datetime
#  updated_at           :datetime
#  deleted_at           :datetime
#  permanent_deleted_at :datetime
#  alvalue              :string(255)
#  category_id          :integer
#  sequence             :integer         default(0)
#

