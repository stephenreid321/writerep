class Email
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :subject, :type => String  
  field :body, :type => String
  field :from_name, :type => String  
  field :from_email, :type => String
  field :from_address1, :type => String
  field :from_postcode, :type => String
  field :delivered_at, :type => Time
  field :message_id, :type => String
  
  belongs_to :decision
  
  validates_presence_of :subject, :body, :from_name, :from_email, :from_address1, :from_postcode, :decision
        
  def self.admin_fields
    {
      :subject => :text,
      :body => :text_area,
      :from_name => :text,
      :from_email => :email,
      :from_address1 => :text,
      :from_postcode => :text,
      :delivered_at => :datetime,
      :message_id => :text,
      :decision_id => :lookup      
    }
  end
  
  def self.human_attribute_name(attr, options={})  
    {
      :from_name => 'Your name',
      :from_email => 'Your email address',
      :from_address1 => 'First line of address',
      :from_postcode => 'Your postcode',
    }[attr.to_sym] || super  
  end   
  
  def body_with_additions
    "Dear #{decision.representative.address_as || decision.representative.name},<br /><br />#{body}<br /><br />Yours sincerely,<br /><br />#{from_name}<br />#{from_address1}<br />#{from_postcode.upcase}"
  end
  
  after_create :send_email
  def send_email
    if Padrino.env == :production
      email = self
      mail = Mail.new
      mail.to = decision.representative.email
      mail.from = "#{from_name} <#{from_email}>"
      mail.bcc = [from_email, decision.campaign.email_bcc].compact
      mail.subject = subject      
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body email.body_with_additions
      end
      mail.html_part = html_part     
      mail = mail.deliver
      update_attribute(:message_id, mail.message_id)
      update_attribute(:delivered_at, Time.now)
    end
  end
    
end
