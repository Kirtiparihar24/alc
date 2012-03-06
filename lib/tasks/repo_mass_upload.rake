require 'find'
require 'spreadsheet'
#require 'devise'

dir_pool = {}

def repo_mass_upload_log(msg)
  f = File.open "#{Rails.root}/log/repo_mass_upload.log", "a+"
  f << "\n"
  f << "*" * 80
  f << "\n"
  f << msg
  f.close
end

report = Spreadsheet::Workbook.new
$sheet = report.create_worksheet
$sheet.row(0).concat ['File Path','Error']
$row_num = 0


def create_document(path, parent)
  file = File.open(path)
  document={:name => file.original_filename, :data=> file}
  document_home = {:document_attributes => document, :folder_id => parent,
    :access_rights => 2, :created_by_user_id=>$lawyer.id, :employee_user_id => $lawyer.id, :company_id=> $lawyer.company_id,
    :mapable_id=>$lawyer.company_id,:mapable_type=>'Company', :category_id => "TODO", :sub_category_id => "TODO", :upload_stage=>1, :user_ids=>[$lawyer.id]}
  newdocument_home = DocumentHome.new(document_home)
  newdocument = newdocument_home.documents.build(document.merge(:company_id=>$lawyer.company_id, :created_by_user_id=>$lawyer.id))
  begin
    unless newdocument_home.save
      $sheet.row($row_num += 1).concat([path, newdocument_home.errors.full_messages.join(".")])
    else
      File.delete path
    end
  rescue Exception => e
    $sheet.row($row_num += 1).concat([path])
    repo_mass_upload_log("#{path}\n#{e.to_s}\n#{e.backtrace.join("\n")}")
  end

  file.close
end

namespace :upload do
  task :new_paperclip => :environment do
    # this script will migrate and reorganize a Paperclip attachments directory to utilize :id_partition
    # Quickly put together by mario@orbitalvoice.com
    # Assumes that your images to migrate < 1 000 000
    #
    # Usage: ruby paperclip_partition_id_migrate.rb TARGET_DIR=/path/to/attachments/:class/:style


    require 'fileutils'

    def add_leading_zeros(i)
      File.basename(i).to_s.rjust(3,'0')
    end

    start = Time.now

    puts "Finding list of directories to be partitioned.."
    company_folders = Dir.glob("assets/company/*")


    puts "#{company_folders.size} companies (folders) to be copied."
    ccount = 0
    company_folders.each do|cfold|
    
    
    TARGET_DIR = "#{cfold}"

    FileUtils.cd(TARGET_DIR)

    dirs_to_move = Dir.glob("docs/*")

    begin
    FileUtils.mkdir '000'
    rescue Exception => e
      p e
      puts "*" * 60
    end

    puts "#{company_folders.size - ccount} companies to process..."
    puts "#{dirs_to_move.size} folders will be consolidated into partitioned folders..."

    puts "Copying existing data into partitioned folders.."
    dirs_to_move.each_with_index do |dir, index|
      parent = "000/"
      parent << add_leading_zeros(File.basename(dir)[0..-4])
      child = File.basename(dir)[-3..-1] || add_leading_zeros(File.basename(dir))
      FileUtils.mkdir_p parent unless FileTest.directory?(parent)
      FileUtils.cp_r dir, "#{parent}/#{child}" if FileTest.directory?(dir)
      puts "#{index} folders copied" if index%1000 == 0 && index > 0
    end

    puts "Partitioned #{dirs_to_move.size} folders into #{Dir.glob("000/*/").size} partitions in #{Time.now - start} seconds."
    ccount += 1

    FileUtils.cd(RAILS_ROOT)
    end

  end

  task :cleanup => :environment do

    email_file = File.open "#{Dir.pwd}/email.txt"
    email = email_file.readline
    email_file.close
    $lawyer = User.find_by_username(email.chomp)
    puts "\n\n\nDeleteing repository records for #{$lawyer.company.name} ..."

    puts "Deleting #{ActiveRecord::Base.connection.execute("select count(*) from documents where document_home_id in 
                (select id from document_homes where company_id = #{$lawyer.company_id} and mapable_type = 'Company')").first["count"]} documents records ..."
    ActiveRecord::Base.connection.execute("delete from documents where document_home_id in 
                (select id from document_homes where company_id = #{$lawyer.company_id} and mapable_type = 'Company')")
    

    puts "Deleting #{ActiveRecord::Base.connection.execute("select count(*) from document_homes where company_id = #{$lawyer.company_id} and mapable_type = 'Company'").first["count"]} document_home records ..."
    ActiveRecord::Base.connection.execute("delete from document_homes where company_id = #{$lawyer.company_id} and mapable_type = 'Company'") 


    puts "Deleting #{ActiveRecord::Base.connection.execute("select count(*) from links where company_id = #{$lawyer.company_id} and mapable_type = 'Company'").first["count"]} links records ..."
    ActiveRecord::Base.connection.execute("delete from links where company_id = #{$lawyer.company_id} and mapable_type = 'Company'") 


    puts "Deleting #{ActiveRecord::Base.connection.execute("select count(*) from folders where company_id = #{$lawyer.company_id} and for_workspace = false").first["count"]} folders records ..."
    ActiveRecord::Base.connection.execute("delete from folders where company_id = #{$lawyer.company_id} and for_workspace = false") 
  end

  task :repository => :environment do
    email_file = File.open "#{Dir.pwd}/email.txt"
    email = email_file.readline
    email_file.close
    $lawyer = User.find_by_username(email.chomp)
    p $lawyer.inspect
    upload_dir = "#{Dir.pwd}/ftp-uploads"
    Find.find(upload_dir) do|path|
      next if File.basename(path).eql?("ftp-uploads")
      parent  = dir_pool[File.dirname(path)]
      if FileTest.directory?(path)
        if path =~ /.*\/(.+)/
          name = $1
        else
          name = path
        end

        new_dir = Folder.new(:company_id => $lawyer.company_id, :created_by_user_id => $lawyer.id, :employee_user_id => $lawyer.id, :name => name, :for_workspace => false, :parent_id => parent)
        begin
          if new_dir.save
            dir_pool[path] = new_dir.id
            #$sheet.row($row_num += 1).concat([path, 'DIR'])
          else
            if parent
              folder = Folder.find_by_name_and_company_id_and_for_workspace_and_parent_id(name, $lawyer.company_id, false, parent)
            else
              folder = Folder.find_by_name_and_company_id_and_for_workspace(name, $lawyer.company_id, false)
            end
            dir_pool[path] = folder.id if folder
            msgs = new_dir.errors.full_messages
            $sheet.row($row_num += 1).concat([path, msgs.join(". ")]) unless folder
          end
        rescue Exception => e
          $sheet.row($row_num += 1).concat([path])
          repo_mass_upload_log("#{path}\n#{e.to_s}\n#{e.backtrace.join("\n")}")
        end
      else
        create_document(path, parent)
      end
    end
    xls_string = StringIO.new ''
    report.write xls_string
    File.open("#{Dir.pwd}/errors.xls", "wb") {|f| f.write(xls_string.string)}
  end
end

# -- Mandeep
