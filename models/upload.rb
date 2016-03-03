class Upload
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Dragonfly::Model

  field :file_name, :type => String
  field :file_uid, :type => String
    
  # Dragonfly
  dragonfly_accessor :file  
    
  def self.admin_fields
    {
      :file_name => {:type => :text, :edit => false},      
      :file => :file
    }
  end
        
end
