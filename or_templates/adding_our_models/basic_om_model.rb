class Record < ActiveFedora::Base

  class DatastreamMetadata < ActiveFedora::NokogiriDatastream

    ##
    # Here's the important part. We're mapping XML into Ruby.
    set_terminology do |t|
      t.root :path => 'root', :xmlns => nil
      t.title
      t.author
      t.url
      t.description
    end

    def self.xml_template
      Nokogiri::XML::Builder.new do |xml|
        xml.root do
          xml.title
          xml.author
          xml.url
          xml.description
        end
      end.doc
    end
  end

  has_metadata :name => "descMetadata", :type => DatastreamMetadata
end
