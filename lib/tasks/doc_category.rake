namespace :doc_category do
  task :add_categories =>:environment do
    categories_for_companies
  end
  
  task :update_repository_documents =>:environment do
     doc_homes=DocumentHome.find(:all, :conditions=> ["mapable_type='Company'"])
     doc_homes.each do |doc_home|
       company= doc_home.company
       doc_home.documents.each do |document|
         #$document.update_attribute(:category_id, company.document_categories.find_by_lvalue('Other').id)
         document.category_id = company.document_categories.find_by_lvalue('Other').id unless document.category_id
         document.send(:update_without_callbacks)
       end
     end
  end
  
  task :add_sub_categories =>:environment do
    article_sub_category = [ 'Legal', 'General','Other']
    template_sub_category = [ 'Forms', 'Formats','Other']
    other_sub_category = ['Other']
    companies = Company.all
    companies.each do |company|
      company.document_categories.each do |category|
        if category.lvalue=='Article'
          article_sub_category.each do |sub_category|
          DocumentSubCategory.create(:lvalue=>sub_category,:category_id=>category.id, :company_id=>company.id)
          end
        elsif category.lvalue=='Template'
          template_sub_category.each do |sub_category|
           DocumentSubCategory.create(:lvalue=>sub_category,:category_id=>category.id, :company_id=>company.id)
            end
         elsif category.lvalue=='Other'
          other_sub_category.each do |sub_category|
              DocumentSubCategory.create(:lvalue=>sub_category,:category_id=>category.id , :company_id=>company.id)
          end
         end
      end
    end
  end

  
    task :update_repository_sub_categories =>:environment do
     doc_homes=DocumentHome.find(:all, :conditions=> ["mapable_type='Company'"])
     links=Link.find(:all, :conditions=> ["mapable_type='Company'"])
     doc_homes.each do |doc_home|
    
       doc_home.documents.each do |document|
            company= document.company
         #$document.update_attribute(:category_id, company.document_categories.find_by_lvalue('Other').id)
         document.category_id = company.document_categories.find_by_lvalue('Other').id unless  company.document_categories.find(:first,document.category_id)
         document.sub_category_id = company.document_sub_categories.find_by_category_id(document.category_id).id
         document.send(:update_without_callbacks)
       end
     end
      links.each do |link|
       #$document.update_attribute(:category_id, company.document_categories.find_by_lvalue('Other').id)
        company= link.company
         link.category_id = company.document_categories.find_by_lvalue('Other').id  unless  company.document_categories.find(:first,link.category_id)
         link.sub_category_id = company.document_sub_categories.find_by_category_id(link.category_id).id
         link.send(:update_without_callbacks)
       end
    

  end

end


def categories_for_companies
  categories = [ 'Article', 'Template','Other']
  companies = Company.all
  companies.each do |company|
    categories.each do |category|
      company.document_categories << DocumentCategory.new(:lvalue=>category)
    end
  end


end
