class TweetRecipient
  include Mongoid::Document
  include Mongoid::Timestamps
  
	belongs_to :tweet
	belongs_to :representative
        
  def self.admin_fields
    {
      :tweet_id => :lookup,
      :representative_id => :lookup
    }
  end
  
end
