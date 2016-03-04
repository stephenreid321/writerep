class Campaign
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :slug, :type => String
  field :background_image_url, :type => String
  field :postcode_lookup_url, :type => String
  field :facebook_share_text, :type => String  
  field :action, :type => String
  field :intro, :type => String
  field :advice, :type => String
  field :thanks, :type => String 
  field :email_subject, :type => String
  field :email_body, :type => String
  field :tweet_body, :type => String  
  
  has_many :decisions, :dependent => :destroy
  
  validates_presence_of :name, :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
        
  def self.admin_fields
    {
      :name => :text,
      :slug => :slug,
      :background_image_url => :text,
      :postcode_lookup_url => :text,      
      :facebook_share_text => :text_area,
      :action => :select,
      :intro => :wysiwyg,
      :advice => :wysiwyg,
      :thanks => :wysiwyg,            
      :email_subject => :text_area,
      :email_body => :text_area,
      :tweet_body => :text_area,      
      :decisions => :collection
    }
  end
    
  before_validation do
    self.postcode_lookup_url = 'http://www.parliament.uk/mps-lords-and-offices/mps/?search_term=' if !self.postcode_lookup_url
  end
  
  def self.actions
    %w{email tweet}
  end
  
  def email?
    action == 'email'
  end
  
  def tweet?
    action == 'tweet'
  end
    
end
