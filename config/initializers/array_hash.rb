class Array
  def map_to_hash
		map { |e| yield e }.inject({}) { |carry, e| carry.merge! e }
	end

			def array_to_hash(key)
    map_to_hash { |e| {e.send(key) => e } }
  end

  def array_hash_value(h_key,v_key,val)
    array_to_hash(h_key)[v_key].send(val)
  end

end
class ActiveSupport::OrderedHash
  def sorted_hash(&block)
    self.class[sort(&block)]
  end
end
