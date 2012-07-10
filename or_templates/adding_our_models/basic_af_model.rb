class Record < ActiveFedora::Base

  has_metadata :name => "descMetadata", :type => ActiveFedora::NokogiriDatastream

end
