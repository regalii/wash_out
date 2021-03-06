xml.instruct!
xml.definitions 'xmlns' => 'http://schemas.xmlsoap.org/wsdl/',
                'xmlns:tns' => @namespace,
                'xmlns:soap' => 'http://schemas.xmlsoap.org/wsdl/soap/',
                'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                'xmlns:soap-enc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                'xmlns:wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
                'name' => @name,
                'targetNamespace' => @namespace do

  xml.types do
    xml.tag! "schema", :targetNamespace => @namespace, :xmlns => 'http://www.w3.org/2001/XMLSchema' do
      defined = []
      @map.each do |operation, formats|
        formats[:in].each do |p|
          wsdl_type xml, p, defined, "InPart"
        end
        formats[:out].each do |p|
          wsdl_type xml, p, defined, "OutPart"
        end
      end
    end
  end

  @map.each do |operation, formats|
    xml.message :name => "#{operation}In" do
      formats[:in].each do |p|
        xml.part wsdl_occurence_part(p, false, :name => "parameters", :element => "tns:#{p.element_type}InPart")
      end
    end
    xml.message :name => "#{formats[:response_tag]}Out" do
      formats[:out].each do |p|
        xml.part wsdl_occurence_part(p, false, :name => "parameters", :element => "tns:#{p.element_type}OutPart")
      end
    end
  end

  xml.portType :name => "#{@name}_port" do
    @map.each do |operation, formats|
      xml.operation :name => operation do
        xml.input :message => "tns:#{operation}In"
        xml.output :message => "tns:#{formats[:response_tag]}Out"
      end
    end
  end

  xml.binding :name => "#{@name}_binding", :type => "tns:#{@name}_port" do
    xml.tag! "soap:binding", :style => 'document', :transport => 'http://schemas.xmlsoap.org/soap/http'
    @map.keys.each do |operation|
      xml.operation :name => operation do
        xml.tag! "soap:operation", :soapAction => operation
        xml.input do
          xml.tag! "soap:body",
            :use => "literal"
        end
        xml.output do
          xml.tag! "soap:body",
            :use => "literal"
        end
      end
    end
  end

  xml.service :name => "service" do
    xml.port :name => "#{@name}_port", :binding => "tns:#{@name}_binding" do
      xml.tag! "soap:address", :location => WashOut::Router.url(request, @name)
    end
  end
end
