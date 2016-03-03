class Tweet
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :body, :type => String
  field :from_name, :type => String  
  field :from_email, :type => String
  field :from_postcode, :type => String
  
  belongs_to :decision
  
  validates_presence_of :body, :from_name, :from_email, :from_postcode, :decision
        
  def self.admin_fields
    {
      :body => :text_area,
      :from_name => :text,
      :from_email => :email,
      :from_postcode => :text
    }
  end
  
  def self.human_attribute_name(attr, options={})  
    {
      :body => 'Tweet',
      :from_name => 'Your name',
      :from_email => 'Your email address',
      :from_postcode => 'Your postcode',
    }[attr.to_sym] || super  
  end    
    
end
