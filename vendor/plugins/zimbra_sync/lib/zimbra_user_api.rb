require 'rubygems'
gem 'soap4r'
require 'soap/element'
require 'soap/rpc/driver'
require 'soap/processor'
require 'soap/streamHandler'
require 'soap/property'
require 'openssl'
require 'digest'
require 'digest/sha1'
require 'net/http'
require 'net/https'
require 'net/protocol'
require 'uri'


module ZimbraUserApi

  # Get current time stamp
  def self.get_timestamp(date = nil)
    if date
      (((Time.parse(date).to_f.to_i)*1000)+1000)
    else
      (((Time.now.to_f.to_i)*1000)+1000)
    end
  end
  
  # This function calculate preauth token.
  def self.calculate_preauth(key, name, timestamp)
    plaintext="#{name}|name|0|#{timestamp}"
    hmacd=OpenSSL::HMAC.new(key,OpenSSL::Digest::Digest.new('sha1'))
    hmacd.update(plaintext)
    preauth =  hmacd.to_s
    return preauth
  end

  def self.generate_parameter_elements(tag_name, hash_obj={})
    element_array = []
    hash_obj.each { |key, value|
      element_array << element(tag_name, value, {:n => key}, [])
    }
    return element_array
  end

  def self.get_user_api_header(authToken)
    header = SOAP::SOAPHeader.new
    context = element('context', nil,{'xmlns' => 'urn:zimbra',},[
        element('authToken', authToken)
      ])
    header.add('context', context)
    return header
  end

  def self.get_user_api_body(request_type, request_parameter,attr_hash)

    body = SOAP::SOAPBody.new(element(request_type, nil,attr_hash, request_parameter))
    return body
  end
  
  # Builds and sends AuthRequest to a provided Zimbra host.
  # Returns a SOAP::Mapping instance, with an authToken attribute
  # It takes uses username and password
  def self.authenticate_with_password(host, name, password)
    header = SOAP::SOAPHeader.new
    body = SOAP::SOAPBody.new(element('AuthRequest', nil,
        {
          'xmlns' => 'urn:zimbraAccount',
        },
        [
          element('account', name, {'by'=>"name"}),
          element('password', password)
        ]
      ))
    envelope = SOAP::SOAPEnvelope.new(header, body)
    return send_soap(envelope, host)
  end

  # Builds and sends AuthRequest to a provided Zimbra host.
  # Returns a SOAP::Mapping instance, with an authToken attribute
  # It takes uses username but not password
  def self.authenticate_with_preauth(host, name, preauth, timestamp)
    header = SOAP::SOAPHeader.new
    body = SOAP::SOAPBody.new(element('AuthRequest', nil,
        {
          'xmlns' => 'urn:zimbraAccount',
        },
        [
          element('account', name, {'by'=>"name"}),
          element('preauth', preauth, {'timestamp' => timestamp, 'expires' => 0})
        ]
      ))

    envelope = SOAP::SOAPEnvelope.new(header, body)
    return send_soap2(envelope, host)
  end

  def self.element(name, value=nil, attrs={}, children=[])
    element = SOAP::SOAPElement.new(name, value)
    element.extraattr.update(attrs) if attrs != nil
    unless children.blank?
      for child in children
        if child
          element.add(child)
        end
      end
    end
    return element
  end

  # Marshals SOAP::Envelopes and sends them to a given Zimbra host
  # Returns response as a SOAP::Mapping instance
  def self.send_soap(envelope, host)
    url = host + '/service/soap/'
    stream = SOAP::HTTPStreamHandler.new(SOAP::Property.new)
    stream.client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE     
    request_string = SOAP::Processor.marshal(envelope)
    puts request_string if $DEBUG
    request = SOAP::StreamHandler::ConnectionData.new(request_string)
    response_string = stream.send(url, request).receive_string
    puts response_string if $DEBUG
    env = SOAP::Processor.unmarshal(response_string)
    return SOAP::Mapping.soap2obj(env.body.root_node)
  end

  def self.send_soap2(envelope, host)
   
    url = host + '/service/soap/'
    stream = SOAP::HTTPStreamHandler.new(SOAP::Property.new)
    stream.client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request_string = SOAP::Processor.marshal(envelope)
    puts request_string if $DEBUG
    request = SOAP::StreamHandler::ConnectionData.new(request_string)
    response_string = stream.send(url, request).receive_string
    puts response_string if $DEBUG
    env = SOAP::Processor.unmarshal(response_string)
    return SOAP::Mapping.soap2obj(env.body.root_node)
  end

  def self.createcontactrequest(host, authToken, contact_hash, location)
    header = get_user_api_header(authToken)
    parameter_elements = []
    parameter_elements <<  element('cn', nil,{'l' => location}, generate_parameter_elements('a', contact_hash))
    #The user has a cn attribute value in the directory equal to the user portion of the Zimbra account and has an objectClass value of 'OrganizationalPerson'.
    #eg.cn=administrator,cn=Users
    attr_hash= {'xmlns' => "urn:zimbraMail"}
    body = get_user_api_body('CreateContactRequest', parameter_elements,attr_hash)
    envelope = SOAP::SOAPEnvelope.new(header, body)
		return send_soap2(envelope, host)
  end

  def self.modifycontactrequest(host, authToken, contact_hash)
    header = get_user_api_header(authToken)
    parameter_elements = []
    parameter_elements <<  element('cn', nil, {:id => contact_hash.delete('zimbra_contact_id').to_s}, generate_parameter_elements('a', contact_hash))

    attr_hash= {'xmlns' => "urn:zimbraMail"}
    body =  get_user_api_body('ModifyContactRequest', parameter_elements,attr_hash)

    envelope = SOAP::SOAPEnvelope.new(header, body)
		return send_soap2(envelope, host)
  end

  def self.deletecontactrequest(host, authToken, zimbra_contact_id)
    header = get_user_api_header(authToken)
    parameter_elements = []
    parameter_elements << element('action',nil, {:id => zimbra_contact_id, :op => 'delete'})

    attr_hash= {'xmlns' => "urn:zimbraMail"}
    body = get_user_api_body('ContactActionRequest', parameter_elements,attr_hash)

    envelope = SOAP::SOAPEnvelope.new(header, body)
		return send_soap2(envelope, host)
  end




  def self.get_task_parameter(zimbra_task_hash,zimbra_comp_hash)

    m_children =[]
    children = {}
    children=zimbra_task_hash.reject { |k,v| !k.eql?("or") && !k.eql?("s") && !k.eql?("e") }

    comp_children=[]
    children.each { |k,v|
      if k.eql?("or")
        comp_children <<  element(k, nil,{"a" => zimbra_task_hash["a"],"d" => v})
      else
        comp_children <<  element(k,nil,{"d"=> v})
      end
    }
    comp_arr=[]
    comp_arr<< element('comp',nil,zimbra_comp_hash,comp_children)

    m_children << element('inv',nil,nil,comp_arr)

    m_children << element('su', zimbra_comp_hash["name"])

    content =[]
    content << element('content', zimbra_task_hash["content"])

    mp_child = []
    mp_child << element('mp',nil,{'ct' => "text/plain"}, content)
    m_children << element('mp', nil, {'ct' => "multipart/alternative"},mp_child)

    return m_children

  end


  def self.createtaskrequest(host, authToken,zimbra_task_hash, zimbra_comp_hash, location)
    header = get_user_api_header(authToken)
    m_children = []
    m_children = get_task_parameter(zimbra_task_hash,zimbra_comp_hash)

    parameter_elements=[]
    parameter_elements << element('m',nil,{'xmlns' => "", 'l' => location.to_s },m_children)

    attr_hash= {'xmlns' => "urn:zimbraMail"}
    body = get_user_api_body('CreateTaskRequest', parameter_elements,attr_hash)
    envelope = SOAP::SOAPEnvelope.new(header, body)

    return send_soap2(envelope, host)
  end


  def self.modifytaskrequest(host, authToken, zimbra_task_hash, zimbra_comp_hash, location)
    header = get_user_api_header(authToken)
    
    m_children=[]
    m_children = get_task_parameter(zimbra_task_hash,zimbra_comp_hash)
    parameter_elements = []
    parameter_elements << element('m',nil, {'xmlns' => "",'l' => location},m_children)

    attr_hash = {'xmlns' => "urn:zimbraMail", 'id'=> zimbra_task_hash["zimbra_task_id"], 'comp' => "0"}
    body =  get_user_api_body('ModifyTaskRequest', parameter_elements, attr_hash)
    envelope = SOAP::SOAPEnvelope.new(header, body)

		return send_soap2(envelope, host)
  end

  def self.deletetaskrequest(host, authToken, zimbra_task_id)
    header =  get_user_api_header(authToken)
    attr_hash = {"xmlns" =>"urn:zimbraMail", "id" => zimbra_task_id, "comp" => "0"}
    body =SOAP::SOAPBody.new(element('CancelTaskRequest', nil,attr_hash))    
    envelope = SOAP::SOAPEnvelope.new(header, body)

		return send_soap2(envelope, host)
  end


  def self.getprefsrequest(host, authToken, name)
    header =  get_user_api_header(authToken)
    parameter_elements = []
    parameter_elements << element('account', name,{"xmlns" => "", "by" => "name"})
    attr_hash ={}
    attr_hash['xmlns'] = 'urn:zimbraAccount'
    body = get_user_api_body('GetPrefsRequest', parameter_elements, attr_hash)
    envelope = SOAP::SOAPEnvelope.new(header, body)
    return  send_soap2(envelope, host)

  end


  def self.get_apt_parameter(apt_hash,apt_comp_hash)

   
    m_children =[]
    inv_child = []
    comp_children = []

    if apt_hash["ex_date"].blank? and !apt_hash["freq"].blank?
      recur_child = []
      add_child =[]
      rule_child = []
      rule_child << element('interval', nil, {"ival" => "1"})
      if apt_hash["count"]
        rule_child << element('count', nil, {"num" => apt_hash["count"]})
      else
        rule_child << element('until', nil, {"d" => apt_hash["until"]})
      end
      add_child << element('rule', nil, {"freq" => apt_hash["freq"]},rule_child)
      recur_child << element('add', nil,nil,add_child )

      comp_children << element('recur', nil, nil, recur_child)

    end

    unless apt_hash["ex_date"].blank?
      # Added exception date time condtion since creating crash with zimbra sync script
      # But need to work on see why it is not adding time
      comp_children << element('exceptId',nil,{'tz' => apt_hash["tz"], "d" => "#{apt_hash["ex_date"]}T#{apt_hash["ex_time"]?apt_hash["ex_time"]:apt_hash["st"]}"})
    end

    if apt_hash["m"]
      alarm_child = []
      trigger_child = []
      trigger_child << element('rel', nil, {"m" => apt_hash["m"], "related" => "START", "neg" => "1"})
      alarm_child << element('trigger', nil, nil, trigger_child)
      comp_children << element('alarm', nil, {"action" => "DISPLAY"},alarm_child)
    end

    if apt_hash["at"]
      at_arr = apt_hash["at"].split(/[",",";"," "]/)
      at_arr.delete("")
      for i in at_arr do
        comp_children << element('at',nil,{'role' => "REQ", 'ptst' => "NE", 'rsvp' => "1", 'a' => i})
        m_children << element('e', nil, {"a" => i, "t" => "t"})
      end
    end
    comp_children << element('s', nil, {"tz" => apt_hash["tz"],"d" => "#{apt_hash["sd"]}T#{apt_hash["st"]}"})
    comp_children << element('e', nil, {"tz" => apt_hash["tz"],"d" => "#{apt_hash["ed"]}T#{apt_hash["et"]}"})
    comp_children << element('or', nil, {"a" => apt_hash["a"], "d" => apt_hash["or"]})


    inv_child << element('comp', nil, apt_comp_hash, comp_children)
    m_children << element('inv', nil, nil, inv_child)
    m_children << element('su',apt_hash["su"])

    mp_child = []
    content_child = []
    content_child << element('content',apt_hash["content"])
    mp_child << element('mp',nil, {"ct" => "text/plain"},content_child)
    m_children << element('mp', nil, {"ct" => "multipart/alternative"},mp_child)
    return m_children

  end

  def self.create_apt_request(host, authToken,apt_hash,apt_comp_hash, location)
    header = get_user_api_header(authToken)

    m_children = []
    m_children = get_apt_parameter(apt_hash,apt_comp_hash)

    parameter_elements = []
    parameter_elements <<  element('m', nil,{'xmlns' => "",'l' => location}, m_children)

    attr_hash = {"xmlns" =>"urn:zimbraMail"}
    body = get_user_api_body('CreateAppointmentRequest', parameter_elements,attr_hash)

    envelope = SOAP::SOAPEnvelope.new(header, body)


    return send_soap2(envelope, host)
  end

  def self.modify_apt_request(host, authToken,apt_hash,apt_comp_hash, location)
    header = get_user_api_header(authToken)
    m_children = []
    m_children = get_apt_parameter(apt_hash,apt_comp_hash)
    parameter_elements = []
    parameter_elements <<  element('m', nil,{'xmlns' => "",'l' => location}, m_children)
    attr_hash = {'xmlns' => "urn:zimbraMail", 'id'=> apt_hash["zimbra_task_id"], 'comp' => "0"}
    body = get_user_api_body('ModifyAppointmentRequest', parameter_elements,attr_hash)
    envelope = SOAP::SOAPEnvelope.new(header, body)

    return send_soap2(envelope, host)
  end

  def self.delete_apt_request(host, authToken, cancel_hash,zimbra_task_id)
    header =  get_user_api_header(authToken)
    m_child = []
    if (cancel_hash["at"])
      at_hash = []
      at_hash = cancel_hash["at"].split(',')
      for i in at_hash do
        m_child << element('e' , nil, {"a" => i, "t" =>"t"})
      end
    end
    m_child << element('su', "Cancelled: "+cancel_hash["su"])
    content_child = []
    content_child << element('Content',cancel_hash["content"])
    mp_child = []
    mp_child << element('mp', nil, {"ct" => "text/plain"}, content_child)
    m_child << element('mp', nil, {"ct" => "multipart/alternative"}, mp_child)
    parameter_elements = []
    parameter_elements << element('m', nil,{"xmlns" =>" "},m_child)
    unless cancel_hash["ex_start_date"].blank?
      #raise cancel_hash["ex_start_date"].inspect
      parameter_elements << element('inst', nil, {'xmlns' => "", 'd' => "#{cancel_hash['ex_start_date']}T#{cancel_hash['ex_start_time']}", 'tz' => cancel_hash['tz']})
    end
    body = get_user_api_body('CancelAppointmentRequest', parameter_elements, {'xmlns' => "urn:zimbraMail",'id' => zimbra_task_id,'comp' => "0"})
    envelope = SOAP::SOAPEnvelope.new(header, body)
		return send_soap2(envelope, host)
  end

  def self.create_exception_apt_request(host, authToken,apt_hash,apt_comp_hash, location)
    header = get_user_api_header(authToken)
    m_children = []
    m_children = get_apt_parameter(apt_hash,apt_comp_hash)
    parameter_elements = []
    parameter_elements <<  element('m', nil,{'xmlns' => "",'l' => location}, m_children)
    attr_hash = {"xmlns" =>"urn:zimbraMail","id" => apt_hash["zimbra_task_id"],"comp"=> "0"}
    body = get_user_api_body('CreateAppointmentExceptionRequest', parameter_elements,attr_hash)
    envelope = SOAP::SOAPEnvelope.new(header, body)
    return send_soap2(envelope, host)
  end

  def self.get_business_contact(host, authToken)
    header = get_user_api_header(authToken)
    #body = get_user_api_body(element('GetContactsRequest',nil,{'_jsns' => "urn:zimbraMail","cn" => {'id'=> "d56fc0fd-c3f8-48b7-a264-6b2717856748:647"}}))

    child = []
    child << element('tz',nil,{'id' => 'Asia/Colombo'})
    child << element('locale',nil,{"_content" => "en_US"})
    child << element('offset', '0')
    child << element('limit', '0')
    child << element('query', nil,{'in' => "Business Contacts","types" => "contact","fetch" => 1})
    body = get_user_api_body('SearchRequest',child,{"_jsns" => {"urn" => "zimbraMail"},"sortBy" => "nameAsc"})
=begin
    child = []
    child << element('_jsns',nil,{'urn' => 'zimbraMail'})
    child << element('cn',nil,{'id' => 'b4f3bfe5-4a0b-46ec-bd34-c37ddaa50ce1:647'})
    body = get_user_api_body('GetContactsRequest',child,nil)
=end
    envelope = SOAP::SOAPEnvelope.new(header, body)
    return send_soap2(envelope, host)
  end

  def self.modifyprefsrequest(host, authToken, zimbra_time_zone)
    header = get_user_api_header(authToken)
    parameter_elements = []
    parameter_elements <<  element('pref', zimbra_time_zone, {'xmlns' => "", "name" => "zimbraPrefTimeZoneId"},nil)
    attr_hash = {"xmlns" => "urn:zimbraAccount", "requestId" =>"0"}
    body = get_user_api_body('ModifyPrefsRequest', parameter_elements,attr_hash)
    envelope = SOAP::SOAPEnvelope.new(header, body)
    return send_soap2(envelope, host)
  end
  
  #--------------------------------------------------------------------------------------------
  # Please don't delete following code. 
  # Kept for future referance
  #--------------------------------------------------------------------------------------------
  
  
  def self.get_cal(host, authToken, start_date, end_date)
    header = get_user_api_header(authToken)

    child = []
#    child << element('query', element('_content', nil, {"inid" =>"10"}), nil)
#    body = get_user_api_body('SearchRequest',child,{"_jsns" => "urn:zimbraMail", "types" => "appointment", "limit" => "500", "fetch" => "all", "calExpandInstStart" => get_timestamp(date), "calExpandInstEnd" => get_timestamp(), "sortBy" => "none", "offset" => 0})

# GetMiniCalRequest request
#    child << element("folder", nil, {"id"=>"10"} )
#    child << element("tz", nil, {"id" => "Asia/Kolkata"})
#    body = get_user_api_body("GetMiniCalRequest", child, {'xmlns' => "urn:zimbraMail", "s"=>get_timestamp(start_date), "e"=>get_timestamp(end_date)}) 
# -----------X--------------

# GetApptSummariesRequest 
#    body = get_user_api_body("GetApptSummariesRequest", nil, {'xmlns' => "urn:zimbraMail", "s"=>get_timestamp(start_date), "e"=>get_timestamp(end_date)}) 
#    body = get_user_api_body("GetApptSummariesRequest", nil, {'xmlns' => "urn:zimbraMail", "s"=>1312050600000, "e"=>1315679400000}) 
#  -----------X--------------

# SearchRequest Request
    child1 = []
#    child1 << element("content", "inid:10", nil,nil) #, [element("inid","10",nil,nil)] )
    child << element("query", "inid:10", nil, nil)
    body = get_user_api_body("SearchRequest", child, {"xmlns" => "urn:zimbraMail", "sortBy" => "none","limit" => "500", "calExpandInstStart" => get_timestamp(start_date),"calExpandInstEnd" => get_timestamp(end_date),"types" => "appointment","offset" => 0}) 
    
    envelope = SOAP::SOAPEnvelope.new(header, body)
    return send_soap2(envelope, host)
  end
  
  def self.get_appointment(host, authToken, id)
  	header = get_user_api_header(authToken)
  	body = get_user_api_body("GetAppointmentRequest", nil, {"id" => "#{id}", "sync" => "1", "includeContent" => 0})
  	envelope = SOAP::SOAPEnvelope.new(header, body)
  	return send_soap2(envelope, host)
  end

end
