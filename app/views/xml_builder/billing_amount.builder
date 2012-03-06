xml = Builder::XmlMarkup.new

xml.graph(:caption=>@dashboard.title,:subcaption=>@dashboard.sub_caption,:rotateNames=>'1',:yaxisname=>'Amount($)',:xaxisname=>'Months',:showOnTop=>'1/0', :formatNumberScale=>'0',:decimalPrecision=>'0',:paletteColors=>"a7d3e8,e03e01,ffb81b,fafafa,61f32e") do
  for item in @dashboard.data
    xml.set(:name=>item[:billing_amount_date], :value=>item[:billing_amount],:color=>'0099CC')
  end
  xml.trendlines do
    xml.line(:startValue=>"#{@dashboard.data[0]? @dashboard.data[0][:upper_thresholds] : '0'}",:color=>"FF0000",:displayValue=>"Upper Threshold",:thickness=>'1')
  end
  xml.trendlines do
    xml.line(:startValue=>"#{@dashboard.data[0]? @dashboard.data[0][:lower_thresholds] : '0'}",:color=>"FF0000",:displayValue=>"Lower Threshold",:thickness=>'1')
  end
end