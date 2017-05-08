class TweetRecipient
  include Mongoid::Document
  include Mongoid::Timestamps
  
	belongs_to :tweet
	belongs_to :decision
        
  def self.admin_fields
    {
      :tweet_id => :lookup,
      :decision_id => :lookup
    }
  end
  
end
