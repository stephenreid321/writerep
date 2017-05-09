module ActivateApp
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Helpers
    register WillPaginate::Sinatra
    helpers Activate::DatetimeHelpers
    helpers Activate::ParamHelpers
    helpers Activate::NavigationHelpers
            
    use Airbrake::Rack::Middleware
    
    set :sessions, :expire_after => 1.year    
    set :public_folder, Padrino.root('app', 'assets')
    set :default_builder, 'ActivateFormBuilder'    
    set :protection, :except => :frame_options
    
    Mail.defaults do            
      delivery_method :smtp, {       
        :address => ENV['SMTP_ADDRESS'] || 'smtp.sendgrid.net',
        :port => ENV['SMTP_PORT'] || 587,
        :domain => ENV['SMTP_DOMAIN'] || 'heroku.com',
        :user_name => ENV['SMTP_USERNAME'] || ENV['SENDGRID_USERNAME'],
        :password => ENV['SMTP_PASSWORD'] || ENV['SENDGRID_PASSWORD'],
        :authentication => ENV['SMTP_AUTH']|| :plain,
        :enable_starttls_auto => ENV['SMTP_STARTTLS'] == 'false' ? false : true
      }   
    end 
       
    before do
      redirect "http://#{ENV['DOMAIN']}#{request.path}" if ENV['DOMAIN'] and request.env['HTTP_HOST'] != ENV['DOMAIN']
      Time.zone = current_account.time_zone if current_account and current_account.time_zone    
      fix_params!
      @_params = params; def params; @_params; end # force controllers to inherit the fixed params
    end        
                
    error do
      Airbrake.notify(env['sinatra.error'], :session => session)
      erb :error, :layout => :application
    end        
    
    not_found do
      erb :not_found, :layout => :application
    end
    
    get '/raise' do
      raise '/raise'
    end
    
    get '/' do
      redirect "/campaigns/#{Campaign.order_by('created_at desc').limit(1).first.slug}"
    end
    
    get '/:slug' do
      if @fragment = Fragment.find_by(slug: params[:slug], page: true)
        erb :page
      else
        pass
      end
    end    
    
    get '/campaigns/:slug' do
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found
      
      @title = @campaign.name
      @og_image = @campaign.background_image_url
      @og_desc = @campaign.facebook_share_text
      
      if @campaign.decisions.count == 1
        @decisions = @campaign.decisions
      elsif params[:postcode]
        @decisions = @campaign.decisions.for_postcode(params[:postcode])
        if @decisions.empty?
          redirect "/campaigns/#{@campaign.slug}?decisions_empty=1"
        end
      end  
      
      if !@decisions
        erb :'campaigns/intro'
      else
        @action = params[:action] || @campaign.action_order_a.first
        case @action
        when 'email'                    
          @relevant_decisions = Decision.where(:id.in => @decisions.select { |decision| decision.representative.email }.map(&:id))      
          @diff = @decisions.where(:id.nin => @relevant_decisions.pluck(:id))
          @resource = @email = @campaign.emails.new subject: @campaign.email_subject, body: @campaign.email_body, from_name: params[:name], from_email: params[:email], from_address1: params[:address1], from_postcode: params[:postcode].try(:upcase) # for next_action
          next_action(current_action: @action) unless @relevant_decisions.count > 0
          erb :'campaigns/email'                    
        when 'tweet'         
          @relevant_decisions = Decision.where(:id.in => @decisions.select { |decision| decision.representative.twitter }.map(&:id))
          @diff = @decisions.where(:id.nin => @relevant_decisions.pluck(:id))
          @resource = @tweet = @campaign.tweets.new body: ".#{@relevant_decisions.map { |decision| decision.representative.twitter }.join(' ')} #{@campaign.tweet_body}", from_name: params[:name], from_email: params[:email], from_address1: params[:address1], from_postcode: params[:postcode].try(:upcase) # for next_action
          next_action(current_action: @action) unless @relevant_decisions.count > 0
          erb :'campaigns/tweet'
        end
      end
    end
    
    post '/campaigns/:slug/email' do
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found
      @resource = @email = @campaign.emails.create!(params[:email])
      params[:representative_ids].each { |representative_id| @email.email_recipients.create! :representative_id => representative_id }
      @email.send_email
      next_action
    end  
        
    post '/campaigns/:slug/tweet' do
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found
      @resource = @tweet = @campaign.tweets.create!(params[:tweet])
      params[:representative_ids].each { |representative_id| @tweet.tweet_recipients.create! :representative_id => representative_id }
      next_action
    end   
    
    get '/campaigns/:slug/thanks' do
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found  
      @title = @campaign.name      
      erb :'campaigns/thanks'
    end    
    
    get '/campaigns/:slug/stats' do
      sign_in_required!
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found  
      @title = @campaign.name            
      erb :'campaigns/stats'
    end
    
    get '/bulk_create_decisions' do    
      @campaign = Campaign.find(request.referrer.split('/').last)   
      redirect "/campaigns/#{@campaign.slug}/bulk_create_decisions"
    end
  
    get '/campaigns/:slug/bulk_create_decisions' do
      sign_in_required!
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found  
      if params[:search]
        @representatives = Representative.where(:archived.ne => true)
        @representatives = @representatives.where(name: /#{Regexp.escape(params[:name])}/i) if params[:name]
        @representatives = @representatives.where(:constituency_id.in => Constituency.where(name: /#{Regexp.escape(params[:constituency])}/i).pluck(:id)) if params[:constituency]
        @representatives = @representatives.where(:party_id => params[:party_id]) if params[:party_id]        
      end
      erb :'campaigns/bulk_create_decisions'
    end 
  
    post '/campaigns/:slug/create_decisions/:representative_id' do
      sign_in_required!  
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found  
      @campaign.decisions.create! representative_id: params[:representative_id]
      200
    end    
       
  end         
end
