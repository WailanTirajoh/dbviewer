Dbviewer::Engine.routes.draw do
  resources :databases, only: [:index, :show] do
    member do
      get 'query'
      post 'query'
    end
  end
  root to: 'databases#index'
end
