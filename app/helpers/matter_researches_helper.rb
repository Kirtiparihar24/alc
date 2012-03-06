module MatterResearchesHelper

  # Returns truncated hoverable parent name.  
  def show_matter_research_parent(research, matter)
    unless research.parent_id.nil?
      truncate_hover_link(research.parent_name, 25, edit_matter_matter_research_path(matter, research.parent)).html_safe!
    end
  end

  # Returns html for delete link, if sub researches length == 0.
  def matter_research_delete_link(r, m, oid)
    if r.sub_researches.length == 0
      return matter_matter_research_path(m, r)
    else
      return "NO"
    end
  end
  
end
