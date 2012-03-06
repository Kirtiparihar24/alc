xml = Builder::XmlMarkup.new
xml.graph(:caption=>@dashboard.title,:rotateNames=>'1',:subcaption=>@dashboard.sub_caption, :yAxisMinValue=>"0",:yAxisMaxValue=>"10", :decimalPrecision=>'2' ,:rotateValues=>'1',:showNames=>'1' ,:numberSuffix=>'' ,:pieSliceDepth=>'10' ,:formatNumberScale=>'0',:xaxisname=>'Weeks', :yaxisname=>'Target (Hrs)') do
  if @dashboard.data != []
  for item in @dashboard.data
		xml.set(:name=>"Week #{item[:billing_amount_date]}",:value=>item[:t_hours],:color=>'974040')
    xml.trendlines do
        xml.line(:startValue=>"#{item[:tget]? item[:tget] : '0'}",:color=>"FF0000",:displayValue=>"Target",:thickness=>'1')
    end
	end
  else
       xml.set(:name=>"Weeks", :value=>0.0001,:color=>"974040")
  end
end
