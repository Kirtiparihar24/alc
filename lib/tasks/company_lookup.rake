namespace :company_lookup do
 task :complookup => :environment do
    @company_lookup=CompanyLookup.find(:all, :conditions=>["alvalue like ?",'A _%'])
    @company_lookup.each do|comp|
    comp_temp=comp.alvalue.split(/^A\s/)[1]
    comp.update_attribute(:alvalue,comp_temp)
    comp.save
    end
  end

  task :find_null_alvalue => :environment do
    @company_lookup=CompanyLookup.find(:all, :conditions=>["alvalue IN (NULL,'')"])
    @company_lookup.each do|comp|
    comp_alvalue=comp.lvalue
    comp.update_attribute(:alvalue,comp_alvalue)
    comp.save
    end
  end

  task :add_lookup_for_first_company => :environment do
    require 'yaml'
    company = Company.find(:all)
    company_values = YAML::load_file("#{RAILS_ROOT}/lib/company/company.yml")
    company.each do |comp|
      company_values.each_pair do |key,val|
        temp_arr = val.split(',')
        temp_arr.each do |arr|
          unless Company.reflect_on_association(key.to_sym).macro == :has_one
            comp.send(key).create(:lvalue => arr.strip, :alvalue => arr.strip)
          else
            eval("comp.create_#{key}(:lvalue=>'#{arr.strip.to_s}',:alvalue =>'#{arr.strip.to_s}')")
          end
        end
      end
    end
  end

  task :add_lookup_for_invoice_billing => :environment do
    require 'yaml'
    company = Company.find(:all)
    company_values = YAML::load_file("#{RAILS_ROOT}/lib/company/company.yml")
    company.each do |comp|
      company_values.each_pair do |key,val|
        if key == "tne_invoice_statuses"
          temp_arr = val.split(',')
          temp_arr.each do |arr|
            unless Company.reflect_on_association(key.to_sym).macro == :has_one
              comp.send(key).create(:lvalue => arr.strip, :alvalue => arr.strip)
            else
              eval("comp.create_#{key}(:lvalue=>'#{arr.strip.to_s}',:alvalue =>'#{arr.strip.to_s}')")
            end
          end
        end
      end
    end
  end

  task :add_lookup_for_matter_type_fact => :environment do
    require 'yaml'
    company = Company.find(:all)
    company_values = YAML::load_file("#{RAILS_ROOT}/lib/company/company.yml")
    company.each do |comp|
      company_lookups = comp.matter_fact_types
      if company_lookups.empty?
        company_values.each_pair do |key,val|
          if key == "matter_fact_types"
            temp_arr = val.split(',')
            temp_arr.each do |arr|
              unless Company.reflect_on_association(key.to_sym).macro == :has_one
                comp.send(key).create(:lvalue => arr.strip, :alvalue => arr.strip)
              else
                eval("comp.create_#{key}(:lvalue=>'#{arr.strip.to_s}',:alvalue =>'#{arr.strip.to_s}')")
              end
            end
          end
        end
      end
    end
  end

  task :add_new_lookup_activity_type => :environment do
    require 'yaml'
    new_lookup = ['Business Development','Client Communications','Document Review','Document Draft / Edit',
                  'Research','Analysis','Preparation','Negotiations','Court Related','Follow Up','Administrative',
                  'CLE','Travel','Other']
    company = Company.find(:all)
    company_values = YAML::load_file("#{RAILS_ROOT}/lib/company/company.yml")
    company.each do |comp|
        puts "------Starting for #{comp.name}---------"
        task_type = comp.task_types.map {|tt| [tt.alvalue]}
        appt_type = comp.appointment_types.map {|at| [at.alvalue]}
        tne_type = comp.activity_types.map {|act| [act.alvalue]}
        collect = task_type + appt_type + tne_type
        collect = (collect.flatten + new_lookup).uniq
        company_values.each_pair do |key,val|
          if key == "task_types"
            #temp_arr = val.split(',')
            collect.each do |arr|
              unless Company.reflect_on_association(key.to_sym).macro == :has_one
                CompanyActivityType.create(:lvalue => arr.strip, :alvalue => arr.strip,:company_id => comp.id) unless arr.nil?
              else
                eval("CompanyActivityType.create_#{key}(:lvalue=>'#{arr.strip.to_s}',:alvalue =>'#{arr.strip.to_s}',:company_id => '#{comp.id}')") unless arr.nil?
              end
            end
          end
        end
        puts "------Completed for #{comp.name}---------"
    end
  end

  task :update_new_lookup_activity_type_to_tne => :environment do    
    company = Company.all
    company.each do |comp|
      company_values= Physical::Timeandexpenses::TimeEntry.find_all_by_company_id(comp.id,:conditions => 'activity_type is not null')
        company_values.each do |val|
          t_e = comp.activity_types.find_by_id(val.activity_type)
          new_t_e = comp.company_activity_types.find_by_alvalue(t_e.alvalue) unless t_e.nil?
          new_t_e = comp.company_activity_types.find_by_alvalue('Other') if new_t_e.nil?
          val.update_attribute('activity_type',new_t_e.id) unless new_t_e.nil?
        end
      end
  end

  task :update_new_lookup_activity_type_to_matter => :environment do    
    company = Company.all
    company.each do |comp|
      company_values= MatterTask.find_with_deleted(:all,:conditions => "category_type_id is not null and company_id = #{comp.id}")
        company_values.each do |val|
          t_e = comp.task_types.find_by_id(val.category_type_id) if val.category == "todo"
          t_e = comp.appointment_types.find_by_id(val.category_type_id) if val.category == "appointment"
          new_t_e = comp.company_activity_types.find_by_alvalue(t_e.alvalue) unless t_e.nil?
          new_t_e = comp.company_activity_types.find_by_alvalue('Other') if new_t_e.nil?
          unless new_t_e.nil?
            val.category_type_id = new_t_e.id
            val.send(:update_without_callbacks)
          end
        end
      end
  end

  task :update_new_lookup_activity_type_to_emp_activity => :environment do    
    company = Company.all
    company.each do |comp|
      company_values= EmployeeActivityRate.find_all_by_company_id(comp.id)
        company_values.each do |val|
          t_e = CompanyLookup.find_by_id(val.activity_type_id)
          new_t_e = comp.company_activity_types.find_by_alvalue(t_e.alvalue) unless t_e.nil?
          new_t_e = comp.company_activity_types.find_by_alvalue('Other') if new_t_e.nil?
          val.update_attribute('activity_type_id', new_t_e.id)
        end
      end
  end

  task :add_new_lookup_document_category => :environment do    
    company = Company.find(:all)
    company.each do |comp|
        p "-------Starting for company----#{comp.name}"
        doc_cat = comp.document_categories.map {|tt| [tt]}
        doc_cat.each do |val|
          DocumentType.create(:lvalue => val[0].lvalue, :alvalue => val[0].alvalue,:company_id => comp.id)
        end
        p "-------Finished for company----#{comp.name}"
    end
  end

  task :update_new_lookup_document_category => :environment do    
    doc = Document.find_with_deleted(:all)
    total = doc.length
    i=0
    doc.each do |val|
        doc_cat = CompanyLookup.find_by_id(val.category_id)
        doc_typ = DocumentType.find_by_alvalue_and_company_id(doc_cat.alvalue,val.company_id) unless doc_cat.nil?
        val.update_attributes({:doc_type_id => doc_typ.id,:category_id => nil}) unless doc_typ.nil?
        i = i + 1
        p "Completed #{i}/#{total}"
    end
  end

  task :update_new_lookup_link_category => :environment do
    doc = Link.find_with_deleted(:all)
    total = doc.length
    i=0
    doc.each do |val|
        doc_cat = CompanyLookup.find_by_id(val.category_id)
        doc_typ = DocumentType.find_by_alvalue_and_company_id(doc_cat.alvalue,val.company_id) unless doc_cat.nil?
        val.update_attributes({:category_id => doc_typ.id}) unless doc_typ.nil?
        i = i + 1
        p "Completed #{i}/#{total}"
    end
  end

  task :update_new_lookup_activity_type_billing => :environment do
    company_values = TneInvoiceTimeEntry.find_with_deleted(:all, :include => [:company])
    total = company_values.length
    i=0
    company_values.each do |val|
      i = i + 1
      t_e = val.company.activity_types.find_by_id(val.activity_type)
      new_t_e = val.company.company_activity_types.find_by_alvalue(t_e.alvalue) unless t_e.nil?
      new_t_e = val.company.company_activity_types.find_by_alvalue('Other') if new_t_e.nil?
      val.update_attribute('activity_type',new_t_e.id) unless new_t_e.nil?
      p "Completed #{i} / #{total}"
    end
  end

  task :update_doc_type_in_document_category => :environment do
    p "Start for Documents---------"
    doc = Document.find_with_deleted(:all)
    total = doc.length
    i=0
    doc.each do |val|
        doc_cat = CompanyLookup.find_by_id(val.doc_type_id)
        doc_typ = DocumentType.find_by_alvalue_and_company_id(doc_cat.alvalue,val.company_id) unless doc_cat.nil?
        if doc_typ.nil?
          cat_other = DocumentType.find_by_alvalue_and_company_id('Other',val.company_id)
          val.update_attributes({:doc_type_id => cat_other.id ,:category_id => nil})
          i = i + 1
        else
          val.update_attributes({:doc_type_id => doc_typ.id ,:category_id => nil})
          i = i + 1
        end
        p "Completed #{i}/#{total}"
    end

    p "Start for Links---------"
    doc = Link.find_with_deleted(:all)
    total = doc.length
    i=0
    doc.each do |val|
        doc_cat = CompanyLookup.find_by_id(val.category_id)
        doc_typ = DocumentType.find_by_alvalue_and_company_id(doc_cat.alvalue,val.company_id) unless doc_cat.nil?
        if doc_typ.nil?
          cat_other = DocumentType.find_by_alvalue_and_company_id('Other',val.company_id)
          val.update_attributes({:category_id => cat_other.id})
          i = i + 1
        else
          val.update_attributes({:category_id => doc_typ.id})
          i = i + 1
        end
        p "Completed #{i}/#{total}"
    end


  end

  task :update_nil_doc_type_of_documents_link => :environment do
    doc = Document.find_with_deleted(:all, :conditions => ["doc_type_id is null"])
    total = doc.length
    i=0
    p "Documents"
    doc.each do |val|
        doc_cat = DocumentType.find_by_alvalue_and_company_id('Other',val.company_id)
        p "11111111"
        p doc_cat.to_yaml
        unless doc_cat.nil?          
          val.update_attributes({:doc_type_id => doc_cat.id ,:category_id => nil})
          i = i + 1
        end
        p "Completed #{i}/#{total}"
    end
    #====================================================================================
    total = 0
    doc = Link.find_with_deleted(:all, :conditions => ["category_id is null"])
    total = doc.length
    i=0
    p "Links"
    doc.each do |val|
        doc_cat = DocumentType.find_by_alvalue_and_company_id('Other',val.company_id)
        p "11111111"
        p doc_cat.to_yaml
        unless doc_cat.nil?
          val.update_attributes({:category_id => doc_cat.id})
          i = i + 1
        end
        p "Completed #{i}/#{total}"
    end
  end

end

