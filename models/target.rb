class Target
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :email, :type => String  
  field :twitter, :type => String
  field :identifier, :type => String
  field :type, :type => String
  
  has_many :decisions, :dependent => :destroy
  
  validates_presence_of :name, :type
  validates_format_of :email, :with => /\A[^@\s]+@[^@\s]+\.[^@\s]+\Z/i, :allow_nil => true
        
  def self.admin_fields
    {
      :name => :text,
      :identifier => :text,
      :email => :email,
      :twitter => :text,
      :type => :text,
      :decisions => :collection      
    }
  end
  
  def self.import_mps
    agent = Mechanize.new
    index_page = agent.get('http://www.parliament.uk/mps-lords-and-offices/mps/')
    index_page.search('#pnlListing table td a[id]').each { |a| 
      mp_page = agent.get(a['href'])
      if name = mp_page.search('h1')[0]
        name = name.text.strip
      end
      if email = mp_page.search('[data-generic-id=email-address] a')[0]
        email = email.text.strip.split(';').first
      end
      if twitter = mp_page.search('[data-generic-id=twitter] a')[0]
        twitter = twitter.text.strip
      end      
      target = Target.create name: name, identifier: mp_page.uri.to_s.split('/').last, type: 'MP'
      target.email = email
      target.save
      target.twitter = twitter
      target.save
    }      
  end
    
end
