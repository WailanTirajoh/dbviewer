Dbviewer::Engine.routes.draw do
  resources :tables, only: [ :index, :show ] do
    member do
      get "query"
      post "query"
      get "export_csv"
      get "new_record"
      post "create_record"
      delete "records/:record_id", to: "tables#destroy_record", as: :destroy_record
      get "records/:record_id/edit", to: "tables#edit_record", as: :edit_record
      patch "records/:record_id", to: "tables#update_record", as: :update_record
    end
  end

  resources :entity_relationship_diagrams, only: [ :index ]

  resources :connections, only: [ :index, :new, :create, :destroy ] do
    member do
      post :update
    end
  end

  resources :logs, only: [ :index ] do
    collection do
      delete :destroy_all
    end
  end

  # Homepage and API endpoints
  get "dashboard", to: "home#index", as: :dashboard

  namespace :api do
    resources :tables, only: [ :index, :show ] do
      collection do
        get "records"
        get "relationships_count"
      end
      member do
        get "relationship_counts"
        get "mini_erd"
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

    resources :connections, only: [] do
      member do
        get "test"
      end
    end
  end

  root to: "home#index"
end
