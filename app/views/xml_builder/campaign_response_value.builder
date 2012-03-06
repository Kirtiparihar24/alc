xml = Builder::XmlMarkup.new


xml.chart(:animation=>'1',:palette=>'4', :caption=>@dashboard.title,:subcaption=>@dashboard.sub_caption,:PYAxisMaxValue=>"100",:PYAxisMinValue=>"10",:SYAxisMinValue=>"10",:SYAxisMaxValue=>"100",:yAxismaxValue=>'100',:yAxisminValue=>"10",:PYAxisName=>'Value',:rotateNames=>'1', :SYAxisName=>'',  :formatNumberScale=>'0', :showValues=>'0',:decimalPrecision=>'1',:anchorSides=>'10',:anchorRadius=>'4',:anchorBorderColor=>'FF8000',:xaxisname=>'Campaigns', :yaxisname=>'Value ($)',:labelDisplay=>'ROTATE') do
	# Run a loop to create the <category> tags within <categories>
  xml.categories do
		for item in @dashboard.data
			xml.category(:label=>item[:hname])
		end
	end
	# Run a loop to create the <set> tags within dataset for series 'Revenue'
  xml.dataset(:seriesName=>'Value Of Opportunity',:color=>'AFD8F8') do
		for item in @dashboard.data
			xml.set(:value=>item[:revenue])
		end
	end
	# Run a loop to create the <set> tags within dataset for series 'Conversion Rate'
  # Set the :parentYAxis attribute to secondary, ie., 'S'
  xml.dataset(:seriesName=>'Conversion Rate',:numberSuffix=>'%25 ', :parentYAxis=>'S',:color=>'FF8000') do
		for item in @dashboard.data
			xml.set(:value=>item[:opps])
		end
	end
end
