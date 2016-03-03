ActivateApp::App.controller do
  
  get '/campaigns/:slug' do
    @campaign = Campaign.find_by(slug: params[:slug]) || not_found
      
    @title = @campaign.name
    @og_image = @campaign.background_image_url
    @og_desc = @campaign.facebook_share_text
      
    if @campaign.decisions.count == 1
      @decision = @campaign.decisions.first
    elsif params[:postcode]
      agent = Mechanize.new
      uri = agent.get("http://www.parliament.uk/mps-lords-and-offices/mps/?search_term=#{params[:postcode]}").uri
      if uri.path != '/mps-lords-and-offices/mps/'          
        @decision = @campaign.decisions.find_by(target_id: Target.find_by(identifier: uri.to_s.split('/').last).try(:id))
      end
      if !@decision
        flash[:error] = 'Not found'
        redirect "/campaigns/#{@campaign.slug}"
      end
    end  
      
    if !@decision
      erb :'campaigns/intro'
    else
      @target = @decision.target
      if @campaign.email?
        @email = @decision.emails.new subject: @campaign.email_subject, body: @campaign.email_body, from_postcode: params[:postcode]
        erb :'campaigns/email'
      elsif @campaign.tweet?
        @tweet = @decision.tweets.new body: "#{@decision.target.twitter} #{@campaign.tweet_body}", from_postcode: params[:postcode]
        erb :'campaigns/tweet'
      end        
    end
  end
    
  post '/campaigns/:slug/:decision_id/email' do
    @campaign = Campaign.find_by(slug: params[:slug]) || not_found
    @decision = @campaign.decisions.find(params[:decision_id])
    @email = @decision.emails.new(params[:email])
    if @email.save
      redirect "/campaigns/#{@campaign.slug}/thanks"
    else
      flash[:error] = 'Some errors prevented the email from being sent'
      erb :'campaigns/email'
    end
  end  
        
  post '/campaigns/:slug/:decision_id/tweet' do
    @campaign = Campaign.find_by(slug: params[:slug]) || not_found
    @decision = @campaign.decisions.find(params[:decision_id])
    @tweet = @decision.tweets.new(params[:tweet])
    if @tweet.save
      redirect "/campaigns/#{@campaign.slug}/thanks"
    else
      flash[:error] = 'Some errors prevented the tweet from being sent'
      erb :'campaigns/tweet'
    end
  end   
    
  get '/campaigns/:slug/thanks' do
    @campaign = Campaign.find_by(slug: params[:slug]) || not_found  
    @title = @campaign.name      
    erb :'campaigns/thanks'
  end    
    
end