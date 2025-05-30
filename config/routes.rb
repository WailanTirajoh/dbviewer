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

  namespace :api do
    resources :tables, only: [ :index ] do
      collection do
        get "records"
        get "relationships_count"
      end
    end

    resources :entity_relationship_diagrams, only: [] do
      collection do
        get "relationships"
        get "table_relationships"
      end
    end

    resource :database, only: [], controller: "database" do
      get "size"
    end

    resources :queries, only: [] do
      collection do
        get "recent"
      end
    end
  end

  root to: "home#index"
end
