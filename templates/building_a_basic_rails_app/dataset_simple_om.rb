class Dataset
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

  ##
  # This stuff is so we can store and retrieve data off the filesystem. Don't worry about it.
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_writer :file
  
  attr_accessor :name
  attr_reader   :errors
  def initialize options={}

    @errors = ActiveModel::Errors.new(self)
    self.ng_xml = self.class.xml_template

    options.each do |k,v|
      send("#{k}=", v)
    end
  end

  def file
    @file ||= "db/datasets/#{Time.now.to_i}"
  end

  def id
    File.basename(file)
  end

  def save
    File.open(file, 'w') { |f| f.puts ng_xml.to_s }
  end

  def persisted?
    File.exists? file
  end

  def self.all
    Dir.glob('db/datasets/*').map do |f|
      Dataset.from_file(f)
    end
  end

  def self.find id
    Dataset.from_file("db/datasets/#{id}")
  end

  def self.from_file f
    d = Dataset.from_xml(File.read(f))

    d.file = f

    d
  end
end
