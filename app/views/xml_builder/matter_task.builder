unless @dashboard.data[0].blank?
	default_check = @dashboard.parameters.values.flatten.uniq.length == 1 &&  @dashboard.parameters.values.flatten.uniq[0].blank?
	xml = Builder::XmlMarkup.new
	xml.graph(:caption=>@dashboard.title,:yAxisMinValue=>"0",:yAxisMaxValue=>"10", :subCaption=>'',:decimalPrecision=>'0' ,:showNames=>'1' ,:numberSuffix=>'' ,:pieSliceDepth=>'10' ,:formatNumberScale=>'0',:yaxisname=>'Tasks' ) do
		xml.categories do
			xml.category(:name=>'')
		end
			xml.dataset(:seriesName=>'Upcoming',:showValues=>"1",:color=>"AFD8F8") do
				xml.set(:value=>@dashboard.data[0]['upcoming']) 		if @dashboard.parameters['upcoming'] == 'upcoming' || default_check

			end


			xml.dataset(:seriesName=>'Today',:showValues=>"1",:color=>"F6BD0F") do
				xml.set(:value=>@dashboard.data[0]['today']) if @dashboard.parameters['today'] == 'today' || default_check
			end


			xml.dataset(:seriesName=>'Overdue',:showValues=>"1",:color=>"FF0000") do
				xml.set(:value=>@dashboard.data[0]['overdue']) if @dashboard.parameters['overdue'] == 'overdue' || default_check
			end

	end
end
