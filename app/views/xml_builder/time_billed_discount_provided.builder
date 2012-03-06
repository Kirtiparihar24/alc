xml = Builder::XmlMarkup.new
xml.graph(:caption=>@dashboard.title,:rotateNames=>'1',:subcaption=>@dashboard.sub_caption,:PYAxisMinValue=>'10',:SYAxisMaxValue=>'20', :formatNumberScale=>'0', :rotateValues=>'1', :placeValuesInside=>'0',:decimalPrecision=>'1',:xaxisname=>'Months', :yaxisname=>'Income($)') do
  # Iterate through the array to create the <category> tags within <categories>
	xml.categories do
		for item in @dashboard.data
        xml.category(:name=>item[:billing_amount_date])
		end
  end
  # Iterate through the array to create the <set> tags within dataset for series 'Time Accounted'
	xml.dataset(:seriesName=>'Bill Amount',:color=>'3D4B81') do
		for item in @dashboard.data
			xml.set(:value=>item[:t_amount] )
		end
  end
  # Iterate through the array to create the <set> tags within dataset for series 'Time Billed'
	xml.dataset(:seriesName=>'Final Amount',:color=>'BF371C') do
		for item in @dashboard.data
			xml.set(:value=>item[:f_amount])
		end
	end
end
