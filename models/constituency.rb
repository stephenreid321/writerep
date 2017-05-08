class Constituency
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :type, :type => String
  
  validates_presence_of :name, :type
  validates_uniqueness_of :name, :scope => :type
  
  has_many :representatives, :dependent => :destroy
        
  def self.admin_fields
    {
      :name => :text,
      :type => :select,
      :representatives => :collection
    }
  end
  
  def self.types
    %w{council_ward london westminster euro}
  end
  
  def self.lookup(postcode)
    agent = Mechanize.new
    page = agent.get("https://www.writetothem.com/who?pc=#{postcode}")    
        
    council_matches = page.body.match(/Your \d+ ([\w ]+) councillors? represents? you on( the)? ([\w ]+)/)
    ward = council_matches[1]
    council = council_matches[-1]
    if london_matches = page.body.match(/Your ([\w ]+) London Assembly Member represents you/)
      london = london_matches[1]
    end
    westminster = page.body.match(/Your ([\w ]+) MP represents you/)[1]
    euro = page.body.match(/Your \d+ ([\w ]+) MEPs? represents? you/)[1]    
    
    {council_ward: "#{ward}, #{council}", london: london, westminster: westminster, euro: euro}      
    
    rescue; {}
  end
  
  def self.for_postcode(postcode)
    where(:id.in => lookup(postcode).map { |type, name|
      if type and name
        find_by(type: type, name: name)
      end
    }.compact.map(&:id))
  end
    
end
