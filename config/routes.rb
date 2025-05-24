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

  # Analytics API endpoints
  get "api/analytics", to: "home#analytics" # Legacy/combined endpoint
  get "api/records", to: "home#records"
  get "api/tables", to: "home#tables_count"
  get "api/relationships", to: "home#relationships_count"
  get "api/database_size", to: "home#database_size"
  get "api/recent_queries", to: "home#recent_queries"

  root to: "home#index"
end
