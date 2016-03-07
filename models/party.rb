class Party
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :image_url, :type => String
  
  validates_presence_of :name
  
  has_many :representatives, :dependent => :destroy
        
  def self.admin_fields
    {
      :name => :text,
      :image_url => :text,
      :representatives => :collection
    }
  end
    
end
