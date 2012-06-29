class OmRecord 
  extend ActiveSupport::Concern

  included do
    ##
    # This stuff is so we can store and retrieve data off the filesystem. Don't worry about it.
    extend ActiveModel::Naming
    include ActiveModel::Conversion

    attr_writer :file
  
    attr_accessor :name
    attr_reader   :errors
  end

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

  class ClassMethods
    def all
      Dir.glob('db/datasets/*').map do |f|
        Dataset.from_file(f)
      end
    end

    def find id
      Dataset.from_file("db/datasets/#{id}")
    end

    def from_file f
      d = Dataset.from_xml(File.read(f))

      d.file = f

      d
    end
  end
end

