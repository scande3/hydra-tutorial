class Dataset < OmRecord # OmRecord contains code that lets us pretend this Dataset is a drop-in replacement for the ActiveRecord.
  include OM::XML::Document

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
