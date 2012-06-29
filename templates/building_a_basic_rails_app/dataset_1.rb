class Dataset
  include OM::XML::Document

  ##
  # Here's the important part. We're mapping XML into Ruby.
  set_terminology do |t|
    t.root :path => 'root', :xmlns => nil
    t.title
    t.author
    t.description
  end

  def self.xml_template
    Nokogiri::XML::Builder.new do |xml|
      xml.root do
        xml.title
        xml.author
        xml.description
      end
    end.doc
  end

  ##
  # This stuff is so we can store and retrieve data off the filesystem. Don't worry about it.
  attr_writer :file
  def initialize options={}

    self.ng_xml = self.class.xml_template

    options.each do |k,v|
      self.k = v
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

  def self.all
    Dir.glob('db/datasets/*').map do |f|
      Dataset.from_file(f)
    end
  end

  def self.find id
    Dataset.from_file("db/datasets/#{id}")
  end

  def self.from_file f
    d = Dataset.load_xml(File.read(f))

    d.file = f

    d
  end

end
