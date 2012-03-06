xml = Builder::XmlMarkup.new
xml.graph(:caption=>@dashboard.title,:rotateNames=>'1',:subcaption=>@dashboard.sub_caption, :decimalPrecision=>'1' , :yAxisMinValue=>"0",:yAxisMaxValue=>"10",:showNames=>'1' ,:rotateValues=>'1',:numberSuffix=>'' ,:pieSliceDepth=>'10' ,:formatNumberScale=>'0',:xaxisname=>'Months', :yaxisname=>'Target (Hrs)' ) do
  if @dashboard.data != []
  for item in @dashboard.data

		xml.set(:name=>item[:billing_amount_date],:value=>item[:t_hours],:color=>'D45050')
    xml.trendlines do
        xml.line(:startValue=>"#{item[:tget]? item[:tget] : '0'}",:color=>"FF0000",:displayValue=>"Target",:thickness=>'1')
    end
	end
  else
       xml.set(:name=>"Months", :value=>0.0001,:color=>"D45050")
  end
end
