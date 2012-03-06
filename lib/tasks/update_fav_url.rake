namespace :update_employee_fav_urls do
  task :update_fav_url =>:environment do
    favs = EmployeeFavorite.all(:conditions => ["fav_type = 'Internal'"])
    favs.each do |fav|
      url = fav.url.split("/")
      u = []

      if url.include?("http:") || url.include?("https:")
        url.each_with_index do |ul, index|
            if index > 2
              u << ul
            end
        end      
        fav.url = u.join("/")
        fav.save(false)
      end

    end
  end
end