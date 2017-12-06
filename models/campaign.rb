class Campaign
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :slug, :type => String
  field :background_image_url, :type => String
  field :facebook_share_text, :type => String  
  field :intro, :type => String  
  field :thanks, :type => String 
  field :email_advice, :type => String
  field :email_subject, :type => String
  field :email_bcc, :type => String
  field :email_body, :type => String
  field :tweet_advice, :type => String
  field :tweet_body, :type => String  
  field :action_order, :type => String, :default => 'email, tweet'
  field :representative_query, :type => String, :default => 'Representative.where(:archived.ne => true)'
  field :metadata, :type => String
  
  def action_order_a
    action_order.split(',').map(&:strip)
  end
  
  has_many :emails, :dependent => :destroy
  has_many :tweets, :dependent => :destroy
  
  validates_presence_of :name, :slug
  validates_uniqueness_of :slug
  validates_format_of :slug, :with => /\A[a-z0-9\-]+\z/
        
  def self.admin_fields
    {
      :name => :text,
      :slug => :slug,
      :background_image_url => :text,      
      :facebook_share_text => :text_area,
      :intro => :wysiwyg,      
      :thanks => :wysiwyg,            
      :email_advice => :wysiwyg,      
      :email_subject => :text,
      :email_bcc => :text,      
      :email_body => :wysiwyg,
      :tweet_advice => :wysiwyg,      
      :tweet_body => :text_area,    
      :action_order => {:type => :text, :new_hint => (new_hint = 'Comma-separated list from {email, tweet}'), :edit_hint => new_hint},
      :representative_query => :text,
      :metadata => :text_area
    }
  end
  
  def representatives
    eval(representative_query)
  end
  
  def email_recipients
    EmailRecipient.where(:email_id.in => emails.pluck(:id))
  end
  
  def tweet_recipients
    TweetRecipient.where(:tweet_id.in => tweets.pluck(:id))
  end
            
  def contacted_representatives
    representatives.where(:id.in => (email_recipients.pluck(:representative_id) + tweet_recipients.pluck(:representative_id)).uniq)
  end
  
  def send_email_recipients_csv(account)
    csv = CSV.generate do |csv|
      csv << %w{name email subject body address1 postcode representative_name representative_constituency representative_party}
      email_recipients.each do |email_recipient|
        email = email_recipient.email
        csv << [
          email.from_name,
          email.from_email,
          email.subject,
          email.body,            
          email.from_address1,
          email.from_postcode,
          email_recipient.representative.name,
          email_recipient.representative.try(:constituency).try(:name),
          email_recipient.representative.try(:constituency).try(:party).try(:name),
        ]
      end
    end
    
    mail = Mail.new
    mail.to = account.email
    mail.from = ENV['MAIL_FROM']
    mail.subject = "CSV for #{name}"
    mail.attachments['email_recipients.csv'] = csv
    mail.deliver   
        
  end
  handle_asynchronously :send_email_recipients_csv
  
end