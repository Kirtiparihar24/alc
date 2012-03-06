xml = Builder::XmlMarkup.new

xml.chart(:caption=>@dashboard.title,:rotateNames=>'1',:subcaption=>@dashboard.sub_caption,:PYAxisMinValue=>'100',:SYAxisMaxValue=>'200',:formatNumberScale=>'0', :rotateValues=>'1', :placeValuesInside=>'1',:decimalPrecision=>'1',:xaxisname=>'Months', :yaxisname=>'Hours') do
  # Iterate through the array to create the <category> tags within <categories>
	xml.categories do
		for item in @dashboard.data
        xml.category(:name=>item[:billing_amount_date])
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
