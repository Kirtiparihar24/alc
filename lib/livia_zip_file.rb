
class LiviaZipFile

  #
  def self.create_zip
    require 'rubygems'
    require 'zip/zip'

        
    Zip::ZipFile.open("livia_docs.zip", Zip::ZipFile::CREATE) do|zf|
      yield(zf)
      
    end
    
  end
  
end