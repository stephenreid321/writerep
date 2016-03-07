class Target
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :address_as, :type => String
  field :email, :type => String  
  field :twitter, :type => String
  field :facebook, :type => String
  field :image_url, :type => String
  field :identifier, :type => String
  field :type, :type => String
  
  has_many :decisions, :dependent => :destroy
  belongs_to :party
  belongs_to :constituency
  
  validates_presence_of :name, :type
  validates_format_of :email, :with => /\A[^@\s]+@[^@\s]+\.[^@\s]+\Z/i, :allow_nil => true
        
  def self.admin_fields
    {
      :name => :text,
      :address_as => :text,   
      :email => :email,
      :twitter => :text,
      :facebook => :text,
      :image_url => :text,
      :identifier => :text,         
      :type => :text,
      :party_id => :lookup,
      :decisions => :collection      
    }
  end
  
  def self.import_mps
    agent = Mechanize.new
    index_page = agent.get('http://www.parliament.uk/mps-lords-and-offices/mps/')
    index_page.search('#pnlListing table td a[id]').each { |a| 
      import_mp(a['href'])
    }      
  end
  
  def self.import_mp(url)
    agent = Mechanize.new
    mp_page = agent.get(url)
    name = mp_page.search('h1')[0].text.strip
    ['Rt Hon ', 'Dr ', 'Sir ', 'Mr ', 'Ms ', 'Mrs ', ' MP', ' QC'].each { |x|
      name = name.gsub(x,'')
    }
    target = Target.create! name: name, identifier: mp_page.uri.to_s.split('/').last, type: 'MP'
    if address_as = mp_page.search('#commons-addressas')[0]
      address_as = address_as.text.strip
      target.update_attributes(address_as: address_as)
    end    
    if email = mp_page.search('[data-generic-id=email-address] a')[0]
      email = email.text.strip.split(';').first
      target.update_attributes(email: email)
    end
    if twitter = mp_page.search('[data-generic-id=twitter] a')[0]
      twitter = twitter.text.strip.split('?').first
      target.update_attributes(twitter: twitter)
    end      
    if facebook = mp_page.search('[data-generic-id=facebook] a')[0]
      target.update_attributes(facebook: facebook['href'])
    end      
    if img = mp_page.search('#member-image img')[0]
      target.update_attributes(image_url: img['src'])
    end           
    p = mp_page.search('#commons-party')[0].text.strip
    p_image = mp_page.search('#imgPartyLogo')[0]['src']
    if party = Party.find_by(name: p) || Party.create(name: p, image_url: p_image)
      target.update_attributes(party: party)
    end
    c = mp_page.search('#commons-constituency')[0].text.strip
    if constituency = Constituency.find_by(name: c) || Constituency.create(name: c, type: 'pcon')
      target.update_attributes(constituency: constituency)
    end
  end
    
end
