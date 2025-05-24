Dbviewer::Engine.routes.draw do
  resources :tables, only: [ :index, :show ] do
    member do
      get "query"
      post "query"
      get "export_csv"
      get "mini_erd"
    end
  end

  resources :entity_relationship_diagrams, only: [ :index ]

  resources :logs, only: [ :index ] do
    collection do
      delete :destroy_all
    end
  end

  # Homepage and API endpoints
  get "dashboard", to: "home#index", as: :dashboard
  get "api/analytics", to: "home#analytics"
  get "api/records", to: "home#records"
  get "api/recent_queries", to: "home#recent_queries"

  root to: "home#index"
end
