class Representative
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :address_as, :type => String
  field :email, :type => String  
  field :twitter, :type => String
  field :facebook, :type => String
  field :image_url, :type => String 
    
  belongs_to :constituency
  belongs_to :party
  
  has_many :decisions, :dependent => :destroy
  
  validates_presence_of :name
  validates_format_of :email, :with => /\A[^@\s]+@[^@\s]+\.[^@\s]+\Z/i, :allow_nil => true
        
  def self.admin_fields
    {
      :name => :text,
      :address_as => :text,   
      :email => :email,
      :twitter => :text,
      :facebook => :text,
      :image_url => :text,
      :constituency_id => :lookup,
      :party_id => :lookup,
      :decisions => :collection      
    }
  end
   
  def self.decode_cfemail(c)  
    k = c[0..1].hex
    m = ''    
    c.chars.each_slice(2).to_a[1..-1].each do |p|
      m += ((p.join.hex)^k).chr
    end
    m
  end  
          
  def firstname
    name.split(' ').first
  end
  
  def self.for_postcode(postcode)
    where(:constituency_id.in => Constituency.for_postcode(postcode).pluck(:id))
  end
      
end
