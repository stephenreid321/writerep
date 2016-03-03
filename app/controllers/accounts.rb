ActivateApp::App.controller :accounts do
  
  get :sign_up do
    redirect url(:accounts, :new) if Provider.registered.empty?
    erb :'accounts/sign_up'
  end    
  
  get :sign_in do
    erb :'accounts/sign_in'
  end    
    
  get :sign_out do
    session.clear
    redirect url(:home)
  end
  
  post :forgot_password do
    if @account = Account.find_by(email: /^#{Regexp.escape(params[:email])}$/i)
      if @account.reset_password!        
        flash[:notice] = "A new password was sent to #{@account.email}"
      else
        flash[:error] = "There was a problem resetting your password."
      end
    else
      flash[:error] = "There's no account registered under that email address."
    end
    redirect url(:home)
  end  
        
  get :new do
    @account = Account.new    
    erb :'accounts/build'
  end 
  
  post :new do
    @account = Account.new(params[:account])
    if session['omniauth.auth']
      @provider = Provider.object(session['omniauth.auth']['provider'])
      @account.provider_links.build(provider: @provider.display_name, provider_uid: session['omniauth.auth']['uid'], omniauth_hash: session['omniauth.auth'])
      @account.picture_url = @provider.image.call(session['omniauth.auth']) unless @account.picture
    end        
    if @account.save
      flash[:notice] = "<strong>Awesome!</strong> Your account was created successfully."
      session['account_id'] = @account.id
      redirect url(:home)
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
      erb :'accounts/build'
    end
  end
      
  get :edit do
    sign_in_required!
    @account = current_account
    erb :'accounts/build'
  end
  
  post :edit do
    sign_in_required!
    @account = current_account
    if @account.update_attributes(params[:account])      
      flash[:notice] = "<strong>Awesome!</strong> Your account was updated successfully."
      redirect url(:accounts, :edit)
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
      erb :'accounts/build'
    end
  end
  
  get :use_picture, :with => :provider do
    sign_in_required!
    @provider = Provider.object(params[:provider])
    @account = current_account
    @account.picture_url = @provider.image.call(@account.provider_links.find_by(provider: @provider.display_name).omniauth_hash)
    if @account.save
      flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Grabbed your picture!"
      redirect url(:accounts, :edit)
    else
      flash.now[:error] = "<strong>Hmm.</strong> There was a problem grabbing your picture."
      erb :'accounts/build'
    end
  end   
  
  get :disconnect, :with => :provider do
    sign_in_required!
    @provider = Provider.object(params[:provider])    
    @account = current_account
    if @account.provider_links.find_by(provider: @provider.display_name).destroy
      flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Disconnected!"
      redirect url(:accounts, :edit)
    else
      flash.now[:error] = "<strong>Oops.</strong> The disconnect wasn't successful."
      erb :'accounts/build'
    end
  end   
   
end