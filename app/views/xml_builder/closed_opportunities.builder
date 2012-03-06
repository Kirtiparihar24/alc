xml = Builder::XmlMarkup.new
xml.graph(:caption=>@dashboard.title,:yAxisMinValue=>"0",:yAxisMaxValue=>"1000",:subcaption=>@dashboard.sub_caption,:rotateNames=>'1', :formatNumberScale=>'0',:decimalPrecision=>'0',:xaxisname=>'Months', :yaxisname=>'Amount($)') do
    for item in @dashboard.data
        xml.set(:name=>"#{item[:opp_date]}"+"(#{item[:opp_count]})", :value=>item[:opp_amount],:color=>'0099CC')
    end
end
