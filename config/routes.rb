Rails.application.routes.draw do
  resources :profile_comments
  resources :plans
  resources :notifications do
    collection do
      get :htmlindex
    end
  end
  resources :cards
  resources :institutions
  # institutions and users are associated via a join model and table named
  # InsitutionUser, and we would occasionally like to see all such associations at a glance
  resources :institution_users
  resources :teams
  resources :work_records
  get 'wallet_transactions/new'
  post 'wallet_transactions/create'
  get 'payment_notifications/create'
  get 'proj_admins/new'
  get "/users/:provider/callback" => "visitors#landing"
  get 'proj_admins/create'
  get 'proj_admins/destroy'
  resources :proj_admins do
    member do
      get :accept, :reject
    end
  end
  resources :assignments do
    member do
      get :accept, :reject, :completed, :confirmed, :confirmation_rejected
    end
  end
  resources :payment_notifications
  resources :donations

  resources :do_for_frees do
    member do
      get :accept, :reject
    end
  end

  resources :do_requests do
    get :autocomplete_project_name, :on => :collection
    member do
      get :accept, :reject
    end
  end

  resources :activities, only: [:index]
  resources :wikis
  resources :tasks
  resources :projects do
    resources :tasks do
      resources :task_comments

     resources :assignments
    end

    resources :project_comments

    member do
      get :accept, :reject
    end

    collection do
      get :autocomplete_project_name
    end

    collection do
      get :htmlindex
    end

    member do
      get :htmlshow
    end
  end
  post '/projects/search_projects', to: 'projects#search_projects'
  post '/projects/:id/save-edits', to: 'projects#saveEdit'
  post '/projects/:id/update-edits', to: 'projects#updateEdit'

  devise_for :users, :controllers => { sessions: 'sessions', registrations: 'registrations', omniauth_callbacks: "omniauth_callbacks"  }
  resources :users do
    member do
      get :profile
    end
  end

  resources :conversations do
    resources :messages
  end

  get 'dashboard' => 'dashboard'

  #restricted mode front-view. See filter in ApplicationController and disable if no longer needed
  get 'visitors' => 'visitors#restricted'

  # root to: 'visitors#index'
  root to: 'visitors#landing'
end
