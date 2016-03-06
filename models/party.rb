class Party
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :image_url, :type => String
  
  validates_presence_of :name
  
  has_many :targets, :dependent => :destroy
        
  def self.admin_fields
    {
      :name => :text,
      :image_url => :text,
      :targets => :collection
    }
  end
    
end
