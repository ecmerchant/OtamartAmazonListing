class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  require 'amazon/ecs'
  require 'peddler'
  require 'nokogiri'
  require 'open-uri'
  require 'gon'

  #rescue_from CanCan::AccessDenied do |exception|
  #  redirect_to "users/sign_in", :alert => exception.message
  #end
  def after_sign_out_path_for(resource)
    new_user_session_path
  end
end
