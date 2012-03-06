xml = Builder::XmlMarkup.new
xml.graph(:caption=> @dashboard.title,:subcaption=>@dashboard.sub_caption,:showPercentageValues=>"1/0", :decimalPrecision=>'0' ,:showNames=>'1' ,:numberSuffix=>'' ,:pieSliceDepth=>'10' ,:formatNumberScale=>'0' ) do
  if @dashboard.data != []
  for item in @dashboard.data
    url= request.raw_host_with_port+'/contacts?contact_type='+item[:contact_status].to_s+'%26mode_type=MY'
		xml.set(:name=>item[:contact_name],:value=>item[:contact_length],:color=>item[:conatact_color],:link=>"http://#{url}")
	end
  else
       xml.set(:name=>"Lead", :value=>0.01,:color=>"FF0000")
       xml.set(:name=>"Clients", :value=>0.01,:color=>"6666FF")
       xml.set(:name=>"Prospects", :value=>0.01,:color=>"CCFF66")
  end
end
