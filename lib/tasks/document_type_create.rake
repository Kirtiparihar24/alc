# Rake task defined to add Agreement,Agreement,Agreement,Closing,Other
# in company_lookups table with type as DocumentType
# It will create new record only if doesn't find record with same type,lvalua,alvalue and company id
# Added By Pratik AJ on 04-05-2011.
namespace :document_type_create do
  task :create_document_type => :environment do
    companies=Company.all
    companies.each do |company|
      ['Agreement',
        'Briefs',
        'Communication',
        'Complaint',
        'Contract',
        'Motion',
        'Notification',
        'Opinion',
        'Research',
        'Report',
        'Statute',
        'Template',
        'Others'].each do |val|
          DocumentType.find_or_create_by_lvalue_and_alvalue_and_company_id(val,val,company.id)
        end      
    end
  end
end