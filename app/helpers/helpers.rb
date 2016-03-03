ActivateApp::App.helpers do
  
  def current_account
    @current_account ||= Account.find(session[:account_id]) if session[:account_id]
  end
   
  def sign_in_required!
    unless current_account
      flash[:notice] = 'You must sign in to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt : redirect(url(:accounts, :sign_in))
    end
  end  
  
  def f(slug)
    (if fragment = Fragment.find_by(slug: slug) and fragment.body
      "\"#{fragment.body.to_s.gsub('"','\"')}\""
    end).to_s
  end  
  
end