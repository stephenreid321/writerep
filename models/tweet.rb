class Tweet
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :body, :type => String
  field :from_name, :type => String  
  field :from_email, :type => String
  field :from_address1, :type => String
  field :from_postcode, :type => String
  
  belongs_to :campaign
  has_many :tweet_recipients, :dependent => :destroy
  
  validates_presence_of :body, :from_name, :from_email, :from_address1, :from_postcode
        
  def self.admin_fields
    {
      :body => :text_area,
      :from_name => :text,
      :from_email => :email,
      :from_address1 => :text,
      :from_postcode => :text,
      :campaign_id => :lookup,
      :tweet_recipients => :collection
    }
  end
  
  def self.human_attribute_name(attr, options={})  
    {
      :body => 'Tweet',
      :from_name => 'Your name',
      :from_email => 'Your email address',
      :from_address1 => 'First line of address',
      :from_postcode => 'Your postcode',
    }[attr.to_sym] || super  
  end    
  
  after_create :post_user_info
  def post_user_info
    if ENV['POST_ENDPOINT']
      agent = Mechanize.new
      begin
        agent.post ENV['POST_ENDPOINT'], {redirect: "http://#{ENV['DOMAIN']}", account: {name: from_name, email: from_email, postcode: from_postcode, source: "#{ENV['DOMAIN']}:#{campaign.slug}"}}
      rescue => e
        Airbrake.notify(e)
      end
    end
  end  
    
end
