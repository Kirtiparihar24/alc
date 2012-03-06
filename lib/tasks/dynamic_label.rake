namespace :livia do
desc "This is rake task for creating Dyanamic label files -"
task :dynamic_label  => :environment do
   abt_paths = "#{RAILS_ROOT}/config/locales/"
   puts abt_paths

    p Dir.pwd
     Dir.chdir(abt_paths)
    p Dir.pwd

   DynamicLabel.all.each do |file|
        name = file.file_name
        file_name = "#{file.file_name}.yml"
    unless File.exist? file_name
      p "-------------- file not found for #{file_name} ----------------------"
      f = File.new(abt_paths + file_name ,"w+")
      exist_file_contents = File.read(abt_paths + "en.yml")
      exist_file_contents = exist_file_contents.sub("en",name)
      f.write(exist_file_contents)
      f.close
      I18n.load_path << abt_paths + file_name
      I18n.reload!
    end
  end
end
end