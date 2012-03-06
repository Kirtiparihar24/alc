xml = Builder::XmlMarkup.new
xml.graph(:caption=>@dashboard.title,:subcaption=>@dashboard.sub_caption,:yAxisminValue=>"10",:formatNumberScale=>'1', :rotateValues=>'1', :placeValuesInside=>'1',:decimalPrecision=>'1',:xaxisname=>'Campaigns', :yaxisname=>'Percentage(%)') do
  # Iterate through the array to create the <category> tags within <categories>
  xml.categories do
		for item in @dashboard.data
      xml.category(:name=>item[:hname])
		end
  end
  # Iterate through the array to create the <set> tags within dataset for series 'Response %'
	xml.dataset(:seriesName=>'Response %25 ',:color=>'AFD8F8') do
		for item in @dashboard.data
			xml.set(:value=>item[:response] )
		end
  end
  # Iterate through the array to create the <set> tags within dataset for series 'Conversion Rate'
	xml.dataset(:seriesName=>'Conversion Rate',:color=>'F6BD0F') do
		for item in @dashboard.data
			xml.set(:value=>item[:opps])
		end
	end
end
