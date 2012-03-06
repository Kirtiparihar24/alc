xml = Builder::XmlMarkup.new
xml.graph(:caption=>@dashboard.title,:subcaption=>"", :yAxisMinValue=>"0",:yAxisMaxValue=>"10",:decimalPrecision=>'0' ,:showNames=>'1' ,:rotateValues=>'1',:formatNumberScale=>'0',:xaxisname=>'Probability', :yaxisname=>'Income ($)') do
  if @dashboard.data != []
  for item in @dashboard.data
		xml.set(:name=>item[:probability],:value=>item[:amount],:color=>'CCFFFF')
	end
  end
end
