# Author Amar
desc "Convert curent locale file into redis i18n"
task :locale_to_redis => :environment do
  
  file_path = "#{Rails.root}/config/locales/"
  en_file_name = "#{file_path}/en.yml"
  us_file_name ="#{file_path}/us.yml"
  # Migrate default En.yml
  DynamicI18n.i18n_yaml_to_redis(en_file_name)  
  DynamicI18n.i18n_yaml_to_redis(us_file_name)  
  Company.find(:all).each do |co|
    
   if co.dynamic_label 
      dl = co.dynamic_label
      i18n_name = co.dynamic_label.file_name.split("_").length>1 ? dl.file_name : "#{dl.file_name}_#{dl.company_id}"
      file_name= "#{Rails.root}/config/locales/#{i18n_name}.yml"
    if File.exist?(file_name) && co.dynamic_label.file_name == i18n_name
      DynamicI18n.i18n_yaml_to_redis(file_name)
      DynamicI18n.add_company(co.id,co.dynamic_label.file_name)
    else
      DynamicI18n.add_company(co.id,i18n_name)
      DynamicI18n.clone_master_data_for_company("#{i18n_name}")
      dl.update_attributes(:file_name=>i18n_name)
    end
   else
      i18n_name = "us_#{co.id}"
      DynamicI18n.add_company(co.id,i18n_name)
      DynamicI18n.clone_master_data_for_company("#{i18n_name}")
      co.build_dynamic_label(:file_name=>i18n_name)  
      co.dynamic_label.save
   end
  end
end

desc "Update New Label "

task :add_new_label_to_redis => :environment do
  file_path = "#{Rails.root}/config/locales/"
  en_file_name = "#{file_path}/en.yml"
  if File.exist?(en_file_name)
     DynamicI18n.update_new_label(en_file_name) 
  end
   
  
end


