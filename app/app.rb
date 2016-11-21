module ActivateApp
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Helpers
    register WillPaginate::Sinatra
    helpers Activate::DatetimeHelpers
    helpers Activate::ParamHelpers
    helpers Activate::NavigationHelpers
            
    use Airbrake::Rack    
    
    set :sessions, :expire_after => 1.year    
    set :public_folder, Padrino.root('app', 'assets')
    set :default_builder, 'ActivateFormBuilder'    
    set :protection, :except => :frame_options
    
    Mail.defaults do
      delivery_method :smtp, {       
        :address => 'smtp.sendgrid.net',
        :port => '587',
        :domain => 'heroku.com',
        :user_name => ENV['SENDGRID_USERNAME'],
        :password => ENV['SENDGRID_PASSWORD'],
        :authentication => :plain,
        :enable_starttls_auto => true
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
        @decision = @campaign.decisions.first
      elsif params[:postcode]
        @decisions = @campaign.decisions_for_postcode(params[:postcode])
        if @decisions.empty?
          flash[:error] = "No representatives of that postcode are part of this campaign"
          redirect "/campaigns/#{@campaign.slug}"
        else
          @decision = @decisions.shuffle.first  
        end
      end  
      
      if !@decision
        erb :'campaigns/intro'
      else
        @representative = @decision.representative
        action = params[:action] || @campaign.action_order_a.first
        case action
        when 'email'
          next_action(current_action: action) unless @decision.representative.email
          @email = @decision.emails.new subject: @campaign.email_subject, body: @campaign.email_body, from_name: params[:name], from_email: params[:email], from_postcode: params[:postcode]
          erb :'campaigns/email'                    
        when 'tweet'
          next_action(current_action: action) unless @decision.representative.twitter
          @tweet = @decision.tweets.new body: ".#{@decision.representative.twitter} #{@campaign.tweet_body}", from_name: params[:name], from_email: params[:email], from_postcode: params[:postcode]
          erb :'campaigns/tweet'
        end
      end
    end
    
    post '/campaigns/:slug/:decision_id/email' do
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found
      @decision = @campaign.decisions.find(params[:decision_id])
      @resource = @email = @decision.emails.new(params[:email])
      if @email.save
        next_action
      else
        flash[:error] = 'Some errors prevented the email from being sent'
        erb :'campaigns/email'
      end
    end  
        
    post '/campaigns/:slug/:decision_id/tweet' do
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found
      @decision = @campaign.decisions.find(params[:decision_id])
      @resource = @tweet = @decision.tweets.new(params[:tweet])
      if @tweet.save
        next_action
      else
        flash[:error] = 'Some errors prevented the tweet from being saved'
        erb :'campaigns/tweet'
      end
    end   
    
    get '/campaigns/:slug/thanks' do
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found  
      @title = @campaign.name      
      erb :'campaigns/thanks'
    end    
    
    get '/bulk_create_decisions' do    
      @campaign = Campaign.find(request.referrer.split('/').last)   
      redirect "/campaigns/#{@campaign.slug}/bulk_create_decisions"
    end
  
    get '/campaigns/:slug/bulk_create_decisions' do
      sign_in_required!
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found  
      if params[:search]
        @representatives = Representative.all
        @representatives = @representatives.where(:email.ne => nil) if params[:email]
        @representatives = @representatives.where(:twitter.ne => nil) if params[:twitter]
        @representatives = @representatives.where(name: /#{Regexp.escape(params[:name])}/i) if params[:name]
        @representatives = @representatives.where(:party_id => params[:party_id]) if params[:party_id]
        @representatives = @representatives.where(:constituency_id.in => Constituency.where(name: /#{Regexp.escape(params[:constituency])}/i).pluck(:id)) if params[:constituency]
        @representatives = @representatives.where(type: params[:type]) if params[:type]      
      end
      erb :'campaigns/bulk_create_decisions'
    end 
  
    post '/campaigns/:slug/create_decisions/:representative_id' do
      sign_in_required!  
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found  
      @campaign.decisions.create! representative_id: params[:representative_id]
      200
    end    
    
    get '/import' do
      sign_in_required!
      erb :import
    end
    
    post '/import/:representatives' do
      sign_in_required!
      Representative.send(:"import_#{params[:representatives]}")
      redirect "/import?imported=#{params[:representatives]}"
    end
   
  end         
end
