class EmailRecipient
  include Mongoid::Document
  include Mongoid::Timestamps
  
	belongs_to :email
	belongs_to :representative
        
  def self.admin_fields
    {
      :email_id => :lookup,
      :representative_id => :lookup
    }
  end
  
end
