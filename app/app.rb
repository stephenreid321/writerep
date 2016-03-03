module ActivateApp
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Helpers
    register WillPaginate::Sinatra
    helpers Activate::DatetimeHelpers
    helpers Activate::ParamHelpers
    helpers Activate::NavigationHelpers
            
    use Dragonfly::Middleware       
    use Airbrake::Rack    
    use OmniAuth::Builder do
      provider :account
      Provider.registered.each { |provider|
        provider provider.omniauth_name, ENV["#{provider.display_name.upcase}_KEY"], ENV["#{provider.display_name.upcase}_SECRET"]
      }
    end 
    OmniAuth.config.on_failure = Proc.new { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }
    
    set :sessions, :expire_after => 1.year    
    set :public_folder, Padrino.root('app', 'assets')
    set :default_builder, 'ActivateFormBuilder'    
    
    Mail.defaults do
      delivery_method :smtp, {
        :user_name => ENV['MAILGUN_SMTP_LOGIN'],
        :password => ENV['MAILGUN_SMTP_PASSWORD'],
        :address => ENV['MAILGUN_SMTP_SERVER'],
        :port => ENV['MAILGUN_SMTP_PORT']
      }   
    end 
       
    before do
      redirect "http://#{ENV['DOMAIN']}#{request.path}" if ENV['DOMAIN'] and request.env['HTTP_HOST'] != ENV['DOMAIN']
      Time.zone = current_account.time_zone if current_account and current_account.time_zone    
      fix_params!
    end        
                
    error do
      Airbrake.notify(env['sinatra.error'], :session => session)
      erb :error, :layout => :application
    end        
    
    not_found do
      erb :not_found, :layout => :application
    end
    
    get :home, :map => '/' do
      redirect "/campaigns/#{Campaign.order_by('created_at desc').limit(1).first.slug}"
    end
    
    get '/campaigns/:slug' do
      @campaign = Campaign.find_by(slug: params[:slug])
      
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
      @campaign = Campaign.find_by(slug: params[:slug])
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
      @campaign = Campaign.find_by(slug: params[:slug])
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
      @campaign = Campaign.find_by(slug: params[:slug])
      erb :'campaigns/thanks'
    end    
    
    get '/:slug' do
      if @fragment = Fragment.find_by(slug: params[:slug], page: true)
        erb :page
      else
        pass
      end
    end    
     
  end         
end
