class Representative
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :address_as, :type => String
  field :email, :type => String  
  field :twitter, :type => String
  field :facebook, :type => String
  field :image_url, :type => String 
  field :archived, :type => Boolean
    
  belongs_to :constituency, optional: true
  belongs_to :party, optional: true
  
  has_many :decisions, :dependent => :destroy
  has_many :email_recipients, :dependent => :destroy
  has_many :tweet_recipients, :dependent => :destroy  
  
  validates_presence_of :name
  validates_format_of :email, :with => /\A[^@\s]+@[^@\s]+\.[^@\s]+\Z/i, :allow_nil => true
  
  before_validation do
    if self.twitter and !self.twitter.starts_with?('@')
      self.twitter = "@#{self.twitter}" 
    end
  end
        
  def self.admin_fields
    {
      :name => :text,
      :address_as => :text,   
      :email => :email,
      :twitter => :text,
      :facebook => :text,
      :image_url => :text,
      :constituency_id => :lookup,
      :party_id => :lookup,
      :decisions => :collection,
      :archived => :check_box
    }
  end
   
  def self.decode_cfemail(c)  
    k = c[0..1].hex
    m = ''    
    c.chars.each_slice(2).to_a[1..-1].each do |p|
      m += ((p.join.hex)^k).chr
    end
    m
  end  
          
  def firstname
    name.split(' ').first
  end
  
  def name_with_party
    if party
      "#{name} (#{party.name})"
    else
      name
    end
  end
  
  def self.for_postcode(postcode, constituencies: nil)
    where(:constituency_id.in => (constituencies or Constituency.for_postcode(postcode)).pluck(:id))
  end
  
  def emails_for(campaign)
    campaign.emails.where(:id.in => email_recipients.pluck(:email_id))
  end
  
  def tweets_for(campaign)
    campaign.tweets.where(:id.in => tweet_recipients.pluck(:tweet_id))
  end  
      
end
