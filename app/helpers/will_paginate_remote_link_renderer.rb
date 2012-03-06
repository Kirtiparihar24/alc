class WillPaginateRemoteLinkRenderer < WillPaginate::LinkRenderer
  def prepare(collection, options, template)
    @remote = options.delete(:remote) || {}
    super
  end

  protected
  def page_link(page, text, attributes = {})
    @template.link_to_remote(text, {:url => url_for(page), :method => :get, :before =>"jQuery('#perpage_loader').show();", :complete=>"jQuery('#perpage_loader').hide();"}.merge(@remote), attributes)
  end
  
end

