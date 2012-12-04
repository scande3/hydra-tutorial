require 'spec_helper'

describe "Editing a record", :type => :feature do
  it "" do
    login_as('archivist1@example.com', 'test123')
  end
  it "Can edit basic content" do
    register_and_login_as('archivist1@example.com')

    visit new_record_path

    fill_in "Title", :with => "This is my record title"
    fill_in "Abstract", :with => "Abstract!"
    click_button "save"

    page.should have_content("This is my record title")
  end
end

def logout
  visit destroy_user_session_path
end

def login_as(email, password)
  logout

  visit new_user_session_path
  fill_in "Email", :with => email 
  fill_in "Password", :with => password
  click_button "Sign in"
end

def register email, password
  visit "/users/sign_up"

  fill_in "Email",                      :with => email
  fill_in "user_password",              :with => password
  fill_in "user_password_confirmation", :with => password

  click_button "Sign up"
end

def register_and_login_as email, password='test123'
  register email, password
  login_as email, password
end
