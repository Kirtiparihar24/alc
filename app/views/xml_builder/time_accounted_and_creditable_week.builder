xml = Builder::XmlMarkup.new

xml.graph(:caption=>@dashboard.title,:rotateNames=>'1',:subcaption=>@dashboard.sub_caption,:PYAxisMinValue=>'10',:SYAxisMaxValue=>'40', :formatNumberScale=>'0', :ProtateValues=>'1', :placeValuesInside=>'1',:rotateValues=>'1',:decimalPrecision=>'1',:xaxisname=>'Weeks', :yaxisname=>'Hours') do

  # Iterate through the array to create the <category> tags within <categories>
	xml.categories do
		for item in @dashboard.data
        xml.category(:name=>"Week #{item[:billing_amount_date]}")
		end
  end
  # Iterate through the array to create the <set> tags within dataset for series 'Time Accounted'
	xml.dataset(:seriesName=>'Time Accounted',:color=>'3D4B81') do
		for item in @dashboard.data
			xml.set(:value=>item[:t_hours] )
		end
  end
  # Iterate through the array to create the <set> tags within dataset for series 'Time Billed'
	xml.dataset(:seriesName=>'Time Billed',:color=>'BF371C') do
		for item in @dashboard.data
			xml.set(:value=>item[:b_hours])
		end
	end
end
