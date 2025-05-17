Dbviewer::Engine.routes.draw do
  resources :databases, only: [ :index, :show ] do
    member do
      get "query"
      post "query"
      get "export_csv"
    end
  end

  # ERD preview route
  get "erd", to: "databases#erd", as: :erd
  resources :logs, only: [ :index ]

  # Homepage
  get "dashboard", to: "home#index", as: :dashboard

  root to: "home#index"
end
