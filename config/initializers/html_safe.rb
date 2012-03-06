# Method 'html_safe!' is overloaded to suppress warning 
class String
  def html_safe!
    self.html_safe
  end
end
