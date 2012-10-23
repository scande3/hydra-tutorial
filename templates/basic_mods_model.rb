class Record < ActiveFedora::Base

  has_metadata :name => 'descMetadata', :type => ModsDescMetadata

  delegate :title,              :to => 'descMetadata', :unique=>true, :at => [:mods, :titleInfo, :title]
  delegate :author,             :to => 'descMetadata', :unique=>true, :at => [:name, :namePart]
  delegate :abstract,           :to => 'descMetadata', :unique=>true
  delegate :preferred_citation, :to => 'descMetadata', :unique=>true
  delegate :related_url,        :to => 'descMetadata', :unique=>true, :at => [:relatedItem, :location, :url]

end

