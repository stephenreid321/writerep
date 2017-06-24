class Decision
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :campaign
  belongs_to :representative
  
  field :verdict, :type => String
  
  validates_presence_of :campaign, :representative
  validates_uniqueness_of :campaign, :scope => :representative
          
  def self.admin_fields
    {
      :summary => {:type => :text, :edit => false},
      :campaign_id => :lookup,
      :representative_id => :lookup,
      :verdict => :text
    }
  end
  
  def self.for_postcode(postcode, constituencies: nil)
    where(:representative_id.in => Representative.for_postcode(postcode, constituencies: constituencies).pluck(:id))
  end
  
  def summary
    "#{representative.name}: #{campaign.name}"
  end
    
end
