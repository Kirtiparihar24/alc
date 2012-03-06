
# Client data is supposed to reside under ftp-uploads folder.
# The folder where client data is stored is set in company settings and stored in companies table
# in the column named "ftp_upload".
# For example careyd's data will be found like:
# ftp-uploads/careyd
# This worker class does the repository upload from the above folder (eg: ftp-uploads/careyd).
# The convention used is:
# ftp-uploads/<client's ftp folder name>/repository/folder(s) to be uploaded
# The RAILS_ROOT/<client's ftp folder name>-repository-log.txt contains log output if any.
# The RAILS_ROOT/<client's ftp folder name>-repository-errors.xls contains error output if any.

class UploadRepository
  @queue = :upload_repository

  def self.repo_mass_upload_log(msg)
    f = File.open("#{RAILS_ROOT}/#{@@ftp_folder}-repository-log.txt", "a+")
    f << "\n#{"*" * 80}\n#{msg}"
    f.close
  end

  def self.strip_inv_chars(fname)
    fname.gsub(')', '').gsub('(','')
  end

  def self.create_document(path, parent)
    file = File.open(path)
    document={:name => strip_inv_chars(file.original_filename), :data=> file}
    document_home = {:document_attributes => document, :folder_id => parent,
      :access_rights => 2, :created_by_user_id=>@@lawyer.id, :employee_user_id => @@lawyer.id, :company_id=> @@lawyer.company_id,
      :mapable_id=>@@lawyer.company_id,:mapable_type=>'Company', :category_id => "TODO", :sub_category_id => "TODO", :upload_stage=>1, :user_ids=>[@@lawyer.id]}
    newdocument_home = DocumentHome.new(document_home)
    newdocument = newdocument_home.documents.build(document.merge(:company_id=>@@lawyer.company_id, :created_by_user_id=>@@lawyer.id))
    begin
      unless newdocument_home.save
        @@sheet.row(@@row_num += 1).concat([path, newdocument_home.errors.full_messages.join(".")])
      else
        # DO NOT DELETE, we are in client's ftp folder!
        # File.delete path 
      end
    rescue Exception => e
      @@sheet.row(@@row_num += 1).concat([path])
      repo_mass_upload_log("#{path}\n#{e.to_s}\n#{e.backtrace.join("\n")}")
    end

    file.close
  end

  def self.perform(euid)
    require 'find'
    require 'spreadsheet'

    dir_pool = {}

    report = Spreadsheet::Workbook.new
    @@sheet = report.create_worksheet
    @@sheet.row(0).concat ['File Path','Error']
    @@row_num = 0
    @@lawyer = User.find(euid)
    @@ftp_folder = @@lawyer.ftp_folder.setting_value
    upload_dir = "#{RAILS_ROOT}/ftp-uploads/#{@@ftp_folder}/repository"
    FileUtils.cd(upload_dir)
    Find.find(".") do|path|
      next if File.basename(path).eql?(".")
      parent  = dir_pool[File.dirname(path)]
      if FileTest.directory?(path)
        name = path =~ /.*\/(.+)/ ? $1 : path
        name = strip_inv_chars(name)
        new_dir = Folder.new(:company_id => @@lawyer.company_id, :created_by_user_id => @@lawyer.id, :employee_user_id => @@lawyer.id, :name => name, :for_workspace => false, :parent_id => parent)
        begin
          if new_dir.save
            dir_pool[path] = new_dir.id
            #$sheet.row($row_num += 1).concat([path, 'DIR'])
          else
            if parent
              folder = Folder.find_by_name_and_company_id_and_for_workspace_and_parent_id(name, @@lawyer.company_id, false, parent)
            else
              folder = Folder.find_by_name_and_company_id_and_for_workspace(name, @@lawyer.company_id, false)
            end
            dir_pool[path] = folder.id if folder
            msgs = new_dir.errors.full_messages
            @@sheet.row(@@row_num += 1).concat([path, msgs.join(". ")]) unless folder
          end
        rescue Exception => e
          @@sheet.row(@@row_num += 1).concat([path])
          repo_mass_upload_log("#{path}\n#{e.to_s}\n#{e.backtrace.join("\n")}")
        end
      else
        create_document(path, parent)
      end
    end
    xls_string = StringIO.new ''
    report.write xls_string
    File.open("#{RAILS_ROOT}/#{@@ftp_folder}-repository-errors.xls", "wb") {|f| f.write(xls_string.string)}
  end
end

