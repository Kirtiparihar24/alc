xml = Builder::XmlMarkup.new
xml.graph(:caption=>@dashboard.title,:subcaption=>@dashboard.sub_caption,:numberPrefix=>'',:isSliced=>'1' , :formatNumberScale=>'0',:decimalPrecision=>'0',:paletteColors=>"a7d3e8,e03e01,ffb81b,fafafa,61f32e") do
#  ?current_tab=fragment-2&amp;stage=Proposal
  if (@dashboard.data!=[])
   for item in @dashboard.data
        url="fragment-1%26mode_type=MY%26" if item[:opp_name] == "Prospecting"
        url="fragment-2%26mode_type=MY%26" if item[:opp_name] == "Proposal"
        url="fragment-3%26mode_type=MY%26" if item[:opp_name] == "Negotiation"
        url="fragment-4%26mode_type=MY%26" if item[:opp_name] == "Final Review"
        xml.set(:name=>"#{item[:opp_name]}"+"($#{item[:opp_value]})", :value=>item[:opp_length],:color=>item[:opp_color], :link=>"http://#{request.raw_host_with_port}/opportunities/manage_opportunities?current_tab=#{url}%26stage=#{item[:opp_name]}")
    end
    else
      xml.set(:name=>"Final Review(0)", :value=>0.01,:color=>"CCCC66")
      xml.set(:name=>"Proposal(0)", :value=>0.01,:color=>"333366")
      xml.set(:name=>"Negotiation(0)", :value=>0.01,:color=>"99FF33")
      xml.set(:name=>"Prospecting(0)", :value=>0.01,:color=>"FF0000")
    end
end
