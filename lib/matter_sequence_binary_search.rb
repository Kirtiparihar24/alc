# To change this template, choose Tools | Templates
# and open the template in the editor.

module MatterSequenceBinarySearch
   
def find_sequnece_no_exists(array_of_sequence_no_used, sequence_no)  
 binary_search(array_of_sequence_no_used.sort,sequence_no.to_s)
end

def bSearch(arr, elem, low, high)
  mid = low+((high-low)/2).to_i  
  if low > high    
    return 0
  end  

  unless arr[mid].nil?   

    if elem.to_i < arr[mid]
      return bSearch(arr, elem, low, mid-1)
    elsif elem.to_i > arr[mid]
      return bSearch(arr, elem, mid+1, high)
    else
      return mid
    end
  end
  
end


def binary_search(a, x)    
  bSearch(a, x, 0, a.length)
end

def find_next_seq_no(sequence_no) 
  next_sequence_no=0  
  basecon = ActiveRecord::Base.connection
  basecon.set_sequence('company'+current_company.id.to_s+'_seq', sequence_no.to_i)
  next_sequence_no = basecon.next_in_sequence('company'+current_company.id.to_s+'_seq')
  basecon=nil

  next_sequence_no
end

end
