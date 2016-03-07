class Decision
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :campaign
  belongs_to :representative
  
  validates_presence_of :campaign, :representative
  validates_uniqueness_of :campaign, :scope => :representative
  
  has_many :emails, :dependent => :destroy
  has_many :tweets, :dependent => :destroy
        
  def self.admin_fields
    {
      :summary => {:type => :text, :edit => false},
      :campaign_id => :lookup,
      :representative_id => :lookup
    }
  end
  
  def summary
    "#{representative.name}: #{campaign.name}"
  end
    
end
