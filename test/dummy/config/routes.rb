Rails.application.routes.draw do
  resources :articles
  mount Dbviewer::Engine => "/dbviewer"

  # Redirect root to dbviewer
  root to: redirect("/dbviewer")
end
