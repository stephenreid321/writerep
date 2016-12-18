class Tweet
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :body, :type => String
  field :from_name, :type => String  
  field :from_email, :type => String
  field :from_address1, :type => String
  field :from_postcode, :type => String
  
  belongs_to :decision
  
  validates_presence_of :body, :from_name, :from_email, :from_address1, :from_postcode, :decision
        
  def self.admin_fields
    {
      :body => :text_area,
      :from_name => :text,
      :from_email => :email,
      :from_address1 => :text,
      :from_postcode => :text
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
      agent.post ENV['POST_ENDPOINT'], {account: {name: from_name, email: from_email, postcode: from_postcode, source: "#{ENV['DOMAIN']}:#{decision.campaign.slug}"}}
    end
  end  
    
end
