module EmployeeFavoritesHelper

  def rss_feed_count(url)
    return "#{EmployeeFavorite.rss_entries_count(url)}"
  end
 
end
