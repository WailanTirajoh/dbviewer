Rails.application.routes.draw do
  resources :articles
  mount Dbviewer::Engine => "/dbviewer"
end
