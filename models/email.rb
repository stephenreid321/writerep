class Email
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :subject, :type => String  
  field :body, :type => String
  field :from_name, :type => String  
  field :from_email, :type => String
  field :from_address1, :type => String
  field :from_postcode, :type => String
  field :message_id, :type => String
  
  belongs_to :campaign
  has_many :email_recipients, :dependent => :destroy
  
  validates_presence_of :subject, :body, :from_name, :from_email, :from_address1, :from_postcode
  validates_format_of :from_email, :with => /\A[^@\s]+@[^@\s]+\.[^@\s]+\Z/i
  validates_uniqueness_of :from_email, :scope => [:campaign, :from_postcode]
    
  def self.admin_fields
    {
      :subject => :text,
      :body => :wysiwyg,
      :from_name => :text,
      :from_email => :email,
      :from_address1 => :text,
      :from_postcode => :text,
      :message_id => :text,
      :campaign_id => :lookup,
      :email_recipients => :collection
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
    "Dear #{email_recipients.map { |email_recipient| email_recipient.representative.firstname }.to_sentence},<br /><br />#{body}<br /><br />Yours sincerely,<br /><br />#{from_name}<br />#{from_address1}<br />#{from_postcode.upcase}"
  end
    
  def send_email
    if ENV['SMTP_USERNAME'] and valid?
      email = self
      mail = Mail.new
      mail.to = email_recipients.map { |email_recipient| "#{email_recipient.representative.name} <#{email_recipient.representative.email}>" }
      mail.from = "#{from_name} <#{from_email}>"
      mail.bcc = [from_email, campaign.email_bcc].compact
      mail.subject = subject      
      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body email.body_with_additions
      end
      mail.html_part = html_part     
      mail = mail.deliver
      update_attribute(:message_id, mail.message_id)
    end
  end
  handle_asynchronously :send_email
  
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
  handle_asynchronously :post_user_info
  
end
