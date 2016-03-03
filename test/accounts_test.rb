require File.expand_path(File.dirname(__FILE__) + '/test_config.rb')

class TestAccounts < ActiveSupport::TestCase
  include Capybara::DSL
    
  setup do
    Account.destroy_all    
  end
  
  test 'signing up' do
    @account = FactoryGirl.build(:account)
    visit '/accounts/sign_up'
    click_link 'Sign up with an email address' if !Provider.registered.empty?
    fill_in 'Name', :with => @account.name
    fill_in 'Email', :with => @account.email
    select @account.time_zone, :from => 'Time zone'
    fill_in 'Password', :with => @account.password
    fill_in 'Password again', :with => @account.password_confirmation
    click_button 'Create account'
    assert page.has_content? 'Your account was created successfully'
  end    
    
  test 'signing in' do
    @account = FactoryGirl.create(:account)
    login_as(@account)
    assert page.has_content? 'Signed in'
  end   
  
end