Wuxilead::Application.routes.draw do

  resources :sliders do
    collection { post :sort }
  end


  mount Ckeditor::Engine => '/ckeditor'

  resources :contents

  match '/home(.:format)',    to: 'static_pages#home'
  match '/about',    to: 'static_pages#about'
  match '/wuxi',    to: 'static_pages#invest'
  match '/services',    to: 'static_pages#services'



  get "static_pages/home"
  get "static_pages/about"
  get "static_pages/contact"
  get "static_pages/services"
  get "static_pages/invest"
  get "static_pages/live"
  get "static_pages/ourteam"
  get "static_pages/news"
  root to: 'static_pages#home'

  resources :users
  resources :sessions, only: [:new, :create, :destroy]
  match '/signup',	to: 'users#new'
  match '/signin',	to: 'sessions#new'
  match '/signout',	to: 'sessions#destroy', via: :delete


  match '/signup',  to: 'users#new'

end
