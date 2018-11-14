Rails.application.routes.draw do
  get 'accounts/regist'
  get 'accounts', to: 'accounts#regist'

  root :to =>'items#get'

  get 'items/get'
  get 'items', to: 'items#get'
  post 'items/get'

  post 'items/regist'

  #post 'items/upload', to: 'items#get'
  post 'items/upload'

  post 'accounts/regist'
  get 'accounts/regist'
  patch 'accounts/regist'

  get 'items/set', to: 'items#set'
  post 'items/set', to: 'items#set'

  get 'items/set_csv'
  post 'items/set_csv'

  get 'items/login_check'

  get 'items/output'
  post 'items/output'

  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
