Dbviewer::Engine.routes.draw do
  resources :tables, only: [ :index, :show ] do
    member do
      get "query"
      post "query"
      get "export_csv"
    end
  end

  # ERD preview route
  get "erd", to: "tables#erd", as: :erd
  resources :logs, only: [ :index ] do
    collection do
      delete :destroy_all
    end
  end

  # Homepage
  get "dashboard", to: "home#index", as: :dashboard

  root to: "home#index"
end
