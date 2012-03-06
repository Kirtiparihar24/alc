xml = Builder::XmlMarkup.new
xml.graph(:caption=>@dashboard.title,
          :subcaption=>@dashboard.sub_caption,
          :decimalPrecision=>'0',
          :showPercentageValues=>"1/0",
          :showNames=>'1' ,
          :numberSuffix=>'' ,
          :pieSliceDepth=>'10' ,
          :formatNumberScale=>'0' ) do
  if @dashboard.data[0][:amount] != 0 || @dashboard.data[1][:amount] != 0
    for item in  @dashboard.data
      xml.set(:name=>item[:name],:value=>item[:amount],:color=>item[:conatact_color])
    end
  else
    xml.set(:name=>"Active", :value=>0.01,:color=>"6666FF")
    xml.set(:name=>"Inactive", :value=>0.01,:color=>"FF0000")
  end
end
