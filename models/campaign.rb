class Campaign
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :slug, :type => String
  field :background_image_url, :type => String
  field :facebook_share_text, :type => String  
  field :intro, :type => String
  field :advice, :type => String
  field :thanks, :type => String 
  field :email_subject, :type => String
  field :email_bcc, :type => String
  field :email_body, :type => String
  field :tweet_body, :type => String  
  field :display_representative_type, :type => Boolean
  field :action_order, :type => String, :default => 'email, tweet'
  
  def action_order_a
    action_order.split(',').map(&:strip)
  end
  
  has_many :decisions, :dependent => :destroy
  
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
      :advice => :wysiwyg,
      :thanks => :wysiwyg,            
      :email_subject => :text,
      :email_bcc => :text,      
      :email_body => :wysiwyg,
      :tweet_body => :text_area,    
      :display_representative_type => :check_box,
      :action_order => {:type => :text, :new_hint => (new_hint = 'Comma-separated list from {email, tweet}'), :edit_hint => new_hint},
      :decisions => {:type => :collection, :edit_hint => '<a class="btn btn-default" href="/bulk_create_decisions">Bulk create decisions</a>'}
    }
  end
        
  def decisions_for_postcode(postcode)
    decisions.where(:representative_id.in => Representative.for_postcode(postcode).pluck(:id))
  end
  
  def emails
    Email.where(:decision_id.in => decisions.pluck(:id))
  end
  
  def tweets
    Tweet.where(:decision_id.in => decisions.pluck(:id))
  end  
  
  def contacted_decisions
    decisions.where(:id.in => (emails.pluck(:decision_id) + tweets.pluck(:decision_id)).uniq)
  end
  
end
