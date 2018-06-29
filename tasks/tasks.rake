
namespace :import do
  
  task :meps => :environment do
    
    agent = Mechanize.new
    rows = []    
    page = agent.get('http://www.europarl.europa.eu/unitedkingdom/en/your-meps/uk_meps.html')
    page.links_with(:href => /#{::Regexp.escape("/unitedkingdom/en/your-meps/uk_meps/")}/).each { |link|
      region_page = agent.get(link.href)
      region_page.search('div.mep').each { |mep|

        row = {
          :name => mep.search('span').first.text,
          :party_name => (p = mep.inner_html.split('National party:').last.split('<').first.strip; !p.blank? ? p : 'Independent'),
          :constituency_name => region_page.title.split(/(Region)? -/).first.strip,
          :constituency_type => 'euro',
          :email => mep.inner_html.split('mailto:')[1].split('>')[1].split('<').first.split(' ').first.strip,
          :image_url => "http://www.europarl.europa.eu#{mep.search('img').first['src']}"
        }
        puts row
        rows << row        
        
      }
    }   
    Representative.import(rows)
    
  end
  
  task :mps => :environment do
    
    Constituency.where(type: 'westminster').each { |constituency|
      constituency.representatives.each { |representative|
        representative.update_attribute(:archived, true)
      }
    }    

    agent = Mechanize.new
    rows = [] 
    
    index_page = agent.get('http://www.parliament.uk/mps-lords-and-offices/mps/')
    index_page.search('#pnlListing table td a[id]').each { |a|
    
      page = agent.get(a['href'])
      
      name = page.search('h1')[0].text.strip
      ['Rt Hon ', 'Dr ', 'Sir ', 'Mr ', 'Ms ', 'Mrs ', ' MP', ' QC'].each { |x|
        name = name.gsub(x,'')
      }
  
      row = {
        :name => name,
        :party_name => page.search('#commons-party')[0].text.strip,
        :party_image_url => page.search('#imgPartyLogo')[0]['src'],
        :constituency_name => page.search('#commons-constituency')[0].text.strip,
        :constituency_type => 'westminster',
        :address_as => (el = page.search('#commons-addressas')[0]) ? el.text.strip : nil,
        :email => (el = page.search('[data-generic-id=email-address] a')[0]) ? el.text : nil,
        :twitter => (el = page.search('[data-generic-id=twitter] a')[0]) ? el.text.strip.split('?').first : nil,
        :facebook => (el = page.search('[data-generic-id=facebook] a')[0]) ? el['href'] : nil,
        :image_url => (el = page.search('#member-image img')[0]) ? el['src'] : nil,          
      }
      puts row
      rows << row
    
    }
    Representative.import(rows)
  
  end
    
end

