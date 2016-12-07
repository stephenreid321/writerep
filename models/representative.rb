class Representative
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, :type => String
  field :type, :type => String  
  field :slug, :type => String  
  field :address_as, :type => String
  field :email, :type => String  
  field :twitter, :type => String
  field :facebook, :type => String
  field :image_url, :type => String 
  
  has_many :decisions, :dependent => :destroy
  belongs_to :party
  belongs_to :constituency
  
  validates_presence_of :name, :type, :slug
  validates_uniqueness_of :slug
  validates_format_of :email, :with => /\A[^@\s]+@[^@\s]+\.[^@\s]+\Z/i, :allow_nil => true
        
  def self.admin_fields
    {
      :name => :text,
      :type => :text,      
      :slug => :text,               
      :address_as => :text,   
      :email => :email,
      :twitter => :text,
      :facebook => :text,
      :image_url => :text,
      :party_id => :lookup,
      :constituency_id => :lookup,
      :decisions => :collection      
    }
  end
 
  def self.importables
    {
      'MPs' => 'mps',
      'London Assembly Members' => 'ams',
      'Hackney Councillors' => 'hackney_councillors',
      'All London Councillors' => 'london_borough_councillors',
      'Bristol City Councillors' => 'bristol_city_councillors',
      'North Somerset Councillors' => 'north_somerset_councillors' 
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
      
  def self.import_mps
    type = 'MP'
    agent = Mechanize.new
    index_page = agent.get('http://www.parliament.uk/mps-lords-and-offices/mps/')
    index_page.search('#pnlListing table td a[id]').each { |a| 
      begin
        import_mp(a['href'])
      rescue
        puts "failed to import #{a['href']}"
      end       
    }     
    import_finished!(type)
  end
  
  def self.import_mp(url)
    type = 'MP'
    agent = Mechanize.new
    page = agent.get(url)
    name = page.search('h1')[0].text.strip
    ['Rt Hon ', 'Dr ', 'Sir ', 'Mr ', 'Ms ', 'Mrs ', ' MP', ' QC'].each { |x|
      name = name.gsub(x,'')
    }    
    puts name
    
    slug = "mp:#{name.parameterize}"    
    representative = Representative.find_by(slug: slug) || Representative.create!(name: name, slug: slug, type: type)
    
    if email = page.search('span[data-cfemail]')[0]
      email = decode_cfemail(email['data-cfemail'])
    end    
    representative.update_attributes(email: email)
    
    if address_as = page.search('#commons-addressas')[0]
      address_as = address_as.text.strip
    end    
    if twitter = page.search('[data-generic-id=twitter] a')[0]
      twitter = twitter.text.strip.split('?').first      
    end      
    if facebook = page.search('[data-generic-id=facebook] a')[0]
      facebook = facebook['href']
    end      
    if img = page.search('#member-image img')[0]
      img = img['src']
    end                   
    representative.update_attributes(address_as: address_as, twitter: twitter, facebook: facebook, image_url: img)
    
    p = page.search('#commons-party')[0].text.strip
    p_image = page.search('#imgPartyLogo')[0]['src']
    if party = Party.find_by(name: p) || Party.create(name: p, image_url: p_image)
      representative.update_attributes(party: party)
    end
    c = page.search('#commons-constituency')[0].text.strip
    if constituency = Constituency.find_by(name: c) || Constituency.create(name: c, type: 'pcon')
      representative.update_attributes(constituency: constituency)
    end
  end
  
  def self.import_ams
    type = 'AM'
    agent = Mechanize.new
    index_page = agent.get('https://www.london.gov.uk/people/assembly')
    index_page.search('a[data-mh=view--related-content]').each { |a| 
      url = "https://www.london.gov.uk#{a['href'].gsub('-0','')}"
      puts url
      page = agent.get(url) 
      if !page.search('li.social-email')[0]
        url = "https://www.london.gov.uk#{a['href'].gsub('-0','')}/more-about"
        puts url
        page = agent.get(url) 
      end
      name = page.search('h1.node__title')[0].text.strip
      puts name
      
      slug = "am:#{name.parameterize}"
      representative = Representative.find_by(slug: slug) || Representative.create!(name: name, slug: slug, type: type)
   
      representative.update_attributes(email: decode_cfemail(page.search('li.social-email a')[0]['data-cfemail']))
      representative.update_attributes(image_url: page.search('img.gla-2-1-medium')[0]['src'])
    
      p = page.search('li.political-group')[0].text.gsub('Party:','').strip
      if party = Party.find_by(name: p) || Party.create(name: p)
        representative.update_attributes(party: party)
      end 
    }     
    import_finished!(type)
  end
    
  def self.import_bristol_city_councillors
    type = 'Bristol City Councillor'
    agent = Mechanize.new
    index_page = agent.get('https://www2.bristol.gov.uk/CouncillorFinder?Task=contact_detail&csvFormat=true')   
    index_page.search('#esiwebapps > div')[0].inner_html.split("<br>")[1..-2].each { |line|     
      name, address, phone1, phone2, phone3, email1, email2, party, ward = *line.split(';').map(&:strip)
      name_parts = name.gsub('Dr.','').gsub('D.R.', '').split(' - ').first.split(' ').map(&:capitalize)
      name = "#{name_parts[0]} #{name_parts[-1]}"
      email = email1.split(' ').last
      
      slug = "bristol-city-council:#{name.parameterize}"
      representative = Representative.find_by(slug: slug) || Representative.create!(name: name, slug: slug, type: type)    

      representative.update_attributes(email: email)
    }    
    import_finished!(type)
  end
  
  def self.import_north_somerset_councillors
    type = 'North Somerset Councillor'
    agent = Mechanize.new
    index_page = agent.get('http://www.n-somerset.gov.uk/my-council/councillors/councillor/find-your-councillors/list-of-councillors/')
    index_page.search('.main-content p a').each { |a| 
      page = agent.get("http://www.n-somerset.gov.uk/#{a['href']}")   
      name = page.search('.service-details .col-sm-8')[0].text.strip
      
      slug = "north-somerset-council:#{name.parameterize}"
      representative = Representative.find_by(slug: slug) || Representative.create!(name: name, slug: slug, type: type)      
      
      representative.update_attributes(email: page.search('.service-details a[href^=mailto]')[0].text.strip)
    }           
    import_finished!(type)
  end
    
  def self.import_london_borough_councillors
    type = 'London Borough Councillor'
    agent = Mechanize.new
    index_page = agent.get('http://www.directory.londoncouncils.gov.uk/')
    index_page.search('#main-content ul a').each { |a| 
      page = agent.get("http://www.directory.londoncouncils.gov.uk#{a['href']}")   
      import_london_table(page, type)
    }      
    import_finished!(type)
  end
  
  def self.import_hackney_councillors
    type = 'Hackney Borough Councillor'
    agent = Mechanize.new    
    page = agent.get("http://www.directory.londoncouncils.gov.uk/directory/hackney/")   
    import_london_table(page, type)
    import_finished!(type)
  end    
  
  def self.import_london_table(page, type)
    borough = page.title.split('London Borough of ').last.strip
    puts borough    
    page.search('.text table tr')[1..-1].each { |tr|
      name = tr.search('td')[0].text.strip.gsub('Cllr ','') 
      email = tr.search('td')[1].text.strip 
      p = tr.search('td')[3].text.strip 
      
      slug = "#{borough.parameterize}-borough-council:#{name.parameterize}"
      representative = Representative.find_by(slug: slug) || Representative.create!(name: name, slug: slug, type: type)
      
      representative.update_attributes(email: email)        
      if party = Party.find_by(name: p) || Party.create(name: p)
        representative.update_attributes(party: party)
      end
    }    
  end
    
  def self.import_finished!(type)
    if ENV['SENDGRID_USERNAME']
      mail = Mail.new
      mail.to = Account.all.map(&:email)
      mail.from = 'no-reply@stephenreid.me'
      mail.subject = "Import of #{type.pluralize} finished"
      mail.deliver   
    end
  end
  
  def self.slugs_for_postcode(postcode)
    agent = Mechanize.new
    page = agent.get("https://www.writetothem.com/who?pc=#{postcode}")    
    slugs = []
    slugs += page.search('ul.mps li a').map(&:text).map { |mp| "mp:#{mp.parameterize}" }
    slugs += page.search('ul.london-assembly-members li a')[0..0].map(&:text).map { |am| "am:#{am.parameterize}" }    
    if rep_blurb = page.search('.rep-blurb')[0]        
      key = rep_blurb.text.match(/councillors? represents? you on( the)? ([\w ]+)/)[-1].parameterize      
      slugs += page.search('ul.councillors li a').map(&:text).map { |councillor| "#{key}:#{councillor.parameterize}" }
    end    
    slugs
  end  
  
  def self.for_postcode(postcode)
    Representative.where(:slug.in => slugs_for_postcode(postcode))
  end
      
end
