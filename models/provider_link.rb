class ProviderLink
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :account
    
  field :provider, :type => String
  field :provider_uid, :type => String
  field :omniauth_hash, :type => Hash
    
  validates_presence_of :provider, :provider_uid, :omniauth_hash
  validates_uniqueness_of :provider, :scope => :account_id
  validates_uniqueness_of :provider_uid, :scope => :provider
      
  def self.admin_fields
    {
      :provider => :text,
      :provider_uid => :text,
      :omniauth_hash => :text_area,
      :account_id => :lookup
    }
  end
  
  alias_method :old_omniauth_hash=, :omniauth_hash=
  def omniauth_hash=(val)
    self.old_omniauth_hash = val.is_a?(String) ? eval(val) : val
  end
   
end
