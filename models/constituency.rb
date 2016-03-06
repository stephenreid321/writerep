class Constituency
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :type, :type => String
  
  validates_presence_of :name, :type
        
  def self.admin_fields
    {
      :name => :text,
      :type => :text
    }
  end
    
end
