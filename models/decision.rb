class Decision
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :campaign
  belongs_to :target
  
  validates_presence_of :campaign, :target
  validates_uniqueness_of :campaign, :scope => :target
  
  has_many :emails, :dependent => :destroy
  has_many :tweets, :dependent => :destroy
        
  def self.admin_fields
    {
      :summary => {:type => :text, :edit => false},
      :campaign_id => :lookup,
      :target_id => :lookup
    }
  end
  
  def summary
    "#{target.name}: #{campaign.name}"
  end
    
end
