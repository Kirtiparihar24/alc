class Float
  def round2
    whole = self.floor
    fraction = self - whole
    if fraction == 0.5
      if (whole % 2) == 0
        whole
      else
        whole+1
      end
    else
      self.round
    end
  end

  def roundf2(places)
    shift = 10**places
    self.nil? ? nil : ((self * shift).round2 / shift.to_f)
  end
  def fixed_precision(places)
    shift = 10**places
    return_f = nil
    unless(self.nil?)
      return_f= ((self * shift).round2 / shift.to_f).to_s
      temp_str = return_f.split('.')
      if(temp_str.length > 1 && temp_str[1].length <=1)
        return_f = "#{return_f}0"
      end
    end
    return return_f
  end
end

