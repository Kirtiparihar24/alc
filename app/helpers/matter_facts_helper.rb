module MatterFactsHelper

  # Returns truncated hoverable parent name.
  def show_matter_fact_parent(fact, matter)
    unless fact.parent_id.nil?
      truncate_hover_link(fact.parent_name, 40, edit_matter_matter_fact_path(matter, fact.parent)).html_safe!
    end
  end

  # Returns html for delete link, if sub facts length == 0.
  def matter_fact_delete_link(fct, mtr, oid)
    if fct.sub_facts.length == 0
      return %Q@
        #{link_to("<span>Reject</span>", matter_matter_fact_path(mtr, fct), :confirm => "Are you sure you want to reject this fact?", :method => :delete)}
      @
    else
      return "<span>Reject</span>"
    end
  end
  
end
