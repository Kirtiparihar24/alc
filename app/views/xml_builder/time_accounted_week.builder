xml = Builder::XmlMarkup.new
xml.graph(:caption=>@dashboard.title,:rotateNames=>'1',:subcaption=>@dashboard.sub_caption, :decimalPrecision=>'2' , :yAxisMinValue=>"0",:yAxisMaxValue=>"10",:showNames=>'1' ,:rotateValues=>'1' ,:pieSliceDepth=>'10' ,:formatNumberScale=>'0',:xaxisname=>'Weeks', :yaxisname=>'Target (Hrs)',:numberSuffix=>"") do
  if @dashboard.data != []
  for item in @dashboard.data

		xml.set(:name=>"Week #{item[:billing_amount_date]}",:value=>item[:t_hours],:color=>'FE2E2E')
	  xml.trendlines do
        xml.line(:startValue=>"#{item[:tget]? item[:tget] : '0'}",:color=>"FF0000",:displayValue=>"Target",:thickness=>'1')
    end
  end
  else
       xml.set(:name=>"Weeks", :value=>0.0001,:color=>"FE2E2E")
  end

end
