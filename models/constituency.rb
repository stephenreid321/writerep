class Constituency
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :type, :type => String
  
  validates_presence_of :name, :type
  
  has_many :representatives, :dependent => :destroy
        
  def self.admin_fields
    {
      :name => :text,
      :type => :select,
      :representatives => :collection
    }
  end
  
  def self.types
    %w{ward london pcon euro}
  end
  
  def self.lookup(postcode)
    agent = Mechanize.new
    page = agent.get("https://www.writetothem.com/who?pc=#{postcode}")    
        
    council_matches = page.body.match(/Your \d+ ([\w ]+) councillors? represents? you on( the)? ([\w ]+)/)
    ward = council_matches[1]
    council = council_matches[-1]
    london = page.body.match(/Your ([\w ]+) London Assembly Member represents you/)[1]
    pcon = page.body.match(/Your ([\w ]+) MP represents you/)[1]
    euro = page.body.match(/Your \d+ ([\w ]+) MEPs? represents? you/)[1]    
    
    {ward: "#{ward}, #{council}", london: london, pcon: pcon, euro: euro}      
  end
  
  def self.for_postcode(postcode)
    where(:id.in => lookup(postcode).map { |type, name| find_by(type: type, name: name) }.compact.map(&:id))
  end
  
end
