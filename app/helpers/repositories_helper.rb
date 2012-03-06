module RepositoriesHelper
  
  def get_docs_links(doc_homes,category_type)
    final=[]
    doc_homes.each do |doc_home|
      if doc_home.class.name=='DocumentHome'
        final << doc_home if doc_home.latest_doc.doc_type_id==category_type.to_i
      elsif doc_home.class.name=='Link'
        final << doc_home if doc_home.category_id==category_type.to_i
      end
    end
    return final
  end

  def get_url(url)
    if url[0..3]=='http'
      return url
    else
      return "http://" + url
    end
  end

end
