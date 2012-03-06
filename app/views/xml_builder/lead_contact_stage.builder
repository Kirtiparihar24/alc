xml = Builder::XmlMarkup.new
xml.graph(:caption=>"#{data[0] && data[0][:title]!='' ? data[0][:title] :  " #{ data[0]? "#{get_employee_user.full_name.titleize} s "+ data[0][:status] : "#{get_employee_user.full_name.titleize}'s"+ ''}" ' Contact Status'}",:subcaption=>"#{data[0][:sub_cap] if data[0]}", :decimalPrecision=>'0' ,:showNames=>'1' ,:numberSuffix=>'' ,:pieSliceDepth=>'10' ,:formatNumberScale=>'0' ) do
  if data != []
  for item in data
		xml.set(:name=>item[:contact_name],:value=>item[:contact_length],:color=>item[:conatact_color])
	end
  end
end