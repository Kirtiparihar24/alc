xml = Builder::XmlMarkup.new
xml.graph(:caption=>@dashboard.title,:subcaption=>"", :decimalPrecision=>'0' ,:showNames=>'1',:numberSuffix=>'' ,:pieSliceDepth=>'10' ,:formatNumberScale=>'0',:xaxisname=>'Key Opportunities', :yaxisname=>'Amount($)') do
  if @dashboard.data != []
   i=0
  for item in @dashboard.data
     if i < 4
       color='215E21'
     else
       color='23238E'
     end
		xml.set(:name=>item[:name],:value=>item[:amount],:hoverText=>item[:hname],:color=>color,:tooltip => item[:name])
    i += 1
	end
  else
       xml.set(:name=>"New", :value=>0.01,:color=>"FF0000")
  end
end
