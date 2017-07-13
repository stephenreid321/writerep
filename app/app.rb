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
        :user_name => ENV['SMTP_USERNAME'],
        :password => ENV['SMTP_PASSWORD'],
        :address => ENV['SMTP_ADDRESS'],
        :port => 587
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
      
      if @campaign.representatives.count == 1
        @representatives = @campaign.representatives
      elsif params[:postcode]
        @representatives = @campaign.representatives.for_postcode(params[:postcode])
        if @representatives.empty?
          redirect "/campaigns/#{@campaign.slug}?representatives_empty=1"
        end
      end  
      
      if !@representatives
        erb :'campaigns/intro'
      else
        @action = params[:action] || @campaign.action_order_a.first
        @relevant_constituencies = Constituency.where(:id.in => @representatives.pluck(:constituency_id))
        case @action
        when 'email'                              
          @relevant_representatives = @representatives.where(:email.ne => nil)
          @diff = @representatives.where(:id.nin => @relevant_representatives.pluck(:id))
          @resource = @email = @campaign.emails.new subject: (ERB.new(@campaign.email_subject).result(binding) if @campaign.email_subject), body: (ERB.new(@campaign.email_body).result(binding) if @campaign.email_body), from_name: params[:name], from_email: params[:email], from_address1: params[:address1], from_postcode: params[:postcode].try(:upcase) # for next_action
          next_action(current_action: @action) unless @relevant_representatives.count > 0
          erb :'campaigns/email'                    
        when 'tweet'        
          @relevant_representatives = @representatives.where(:twitter.ne => nil)
          @diff = @representatives.where(:id.nin => @relevant_representatives.pluck(:id))
          @resource = @tweet = @campaign.tweets.new body: ".#{@relevant_representatives.pluck(:twitter).join(' ')} #{(ERB.new(@campaign.tweet_body).result(binding) if @campaign.tweet_body)}", from_name: params[:name], from_email: params[:email], from_address1: params[:address1], from_postcode: params[:postcode].try(:upcase) # for next_action
          next_action(current_action: @action) unless @relevant_representatives.count > 0
          erb :'campaigns/tweet'
        end
      end
    end
    
    get '/campaigns/:slug/next_action/:action' do
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found
      next_action(current_action: params[:action])
    end
    
    post '/campaigns/:slug/email' do
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found
      begin
        @resource = @email = @campaign.emails.create!(params[:email])
        params[:representative_ids].each { |representative_id| @email.email_recipients.create! :representative_id => representative_id }
        @email.send_email      
        next_action
      rescue => e
        Airbrake.notify(e)
        flash[:error] = 'There was an error sending the email. Please check your information and try again.'              
        redirect back
      end
    end  
        
    post '/campaigns/:slug/tweet' do
      @campaign = Campaign.find_by(slug: params[:slug]) || not_found
      begin
        @resource = @tweet = @campaign.tweets.create!(params[:tweet])
        params[:representative_ids].each { |representative_id| @tweet.tweet_recipients.create! :representative_id => representative_id }
        next_action
      rescue => e
        Airbrake.notify(e)
        flash[:error] = 'There was an error saving the tweet. Please check your information and try again.'      
        redirect back
      end      
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
               
  end         
end

