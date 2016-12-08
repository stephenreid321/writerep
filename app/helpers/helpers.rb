ActivateApp::App.helpers do
  
  def current_account
    @current_account ||= Account.find(session[:account_id]) if session[:account_id]
  end
  
  def next_action(current_action: uri.split('/').last)
    next_action = @campaign.action_order_a[@campaign.action_order_a.index(current_action)+1]
    next_action ? redirect("/campaigns/#{@campaign.slug}?action=#{next_action}&name=#{@resource.try(:from_name)}&email=#{@resource.try(:from_email)}&address1=#{@resource.try(:from_address1)}&postcode=#{@resource.try(:from_postcode)}") : redirect("/campaigns/#{@campaign.slug}/thanks")  
  end
   
  def sign_in_required!
    unless current_account
      flash[:notice] = 'You must sign in to access that page'
      session[:return_to] = request.url
      request.xhr? ? halt : redirect('/admin')
    end
  end  
       
  def f(slug)
    (if fragment = Fragment.find_by(slug: slug) and fragment.body
        "\"#{fragment.body.to_s.gsub('"','\"')}\""
      end).to_s
  end  
  
end