
namespace :import do
  
  task :ppcs => :environment do
    csv = CSV.parse(open('https://candidates.democracyclub.org.uk/media/candidates-parl.2017-06-08.csv').read, headers: true)
    csv.each { |row|
      puts row['name']
      party = Party.find_or_create_by!(name: row['party_name'])
      constituency = Constituency.find_or_create_by!(name: row['post_label'].gsub('-Super','-super'), type: 'westminster')
      representative = Representative.find_or_create_by!(name: row['name'], party: party, constituency: constituency)
      representative.archived = nil
      if representative.email != row['email']
        puts "*** email changed: #{representative.email} -> #{row['email']}"
        representative.email = row['email']
      end
      t = representative.twitter ? representative.twitter.gsub('@','') : nil
      if t != row['twitter_username']
        puts "*** twitter changed: #{t} -> #{row['twitter_username']}"
        representative.twitter = row['twitter_username']
      end
      representative.save
    }    
  end
  
  task :mps => :environment do

    agent = Mechanize.new

    # twfy_page = agent.get('https://www.theyworkforyou.com/mps/')
    # twfy_map = Hash[twfy_page.search('.people-list__person').map { |div|
    #     [div.search('.people-list__person__constituency').text.parameterize,
    #       div.search('.people-list__person__name').text,
    #     ]
    #   }]

    index_page = agent.get('http://www.parliament.uk/mps-lords-and-offices/mps/')
    index_page.search('#pnlListing table td a[id]').each { |a|
      begin
        import_mp(a['href'], name: twfy_map[a.parent.parent.search('td').last.text.parameterize])
      rescue
        puts "failed to import #{a['href']}"
      end
    }
    import_finished!(type)  
  
  end
  
  task :mp => :environment do
    
    agent = Mechanize.new
    page = agent.get(url)
    if !name
      name = page.search('h1')[0].text.strip
      ['Rt Hon ', 'Dr ', 'Sir ', 'Mr ', 'Ms ', 'Mrs ', ' MP', ' QC'].each { |x|
        name = name.gsub(x,'')
      }
    end

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
  
  task :ams => :environment do
    
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
  
  task :bristol_city_councillors => :environment do
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

  task :north_somerset_councillors => :environment do
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
  
  task :london_borough_councillors => :environment do
    type = 'London Borough Councillor'
    agent = Mechanize.new
    index_page = agent.get('http://www.directory.londoncouncils.gov.uk/')
    index_page.search('#main-content ul a').each { |a|
      page = agent.get("http://www.directory.londoncouncils.gov.uk#{a['href']}")
      import_london_table(page, type)
    }
    import_finished!(type)  
  end
  
  task :hackney_borough_councillors => :environment do
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
    if (ENV['SMTP_USERNAME'] or ENV['SENDGRID_USERNAME'])
      mail = Mail.new
      mail.to = Account.all.map(&:email)
      mail.from = "Campaign Kit <no-reply@#{ENV['DOMAIN']}>"
      mail.subject = "Import of #{type.pluralize} finished"
      mail.deliver
    end
  end   
  
end

