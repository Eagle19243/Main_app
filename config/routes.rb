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
  post 'team_memberships/:project_id', to: 'teams#team_memberships'
  resources :work_records
  get 'wallet_transactions/new'
  post 'wallet_transactions/create'
  get 'payment_notifications/create'

  get 'proj_admins/new'

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

  get 'projects/featured', as: :featured_projects
  get '/projects/:id/old', to: 'projects#old_show'
  resources :do_requests do
    member do
      get :accept, :reject
    end
  end

  resources :activities, only: [:index]
  resources :wikis
  resources :tasks
  resources :favorite_projects, only: [:create, :destroy]

  resources :projects do
    resources :tasks do
  	 resources :task_comments

     resources :assignments
    end

    resources :project_comments

    member do
      get :accept, :reject
      post :follow
      post :rate
    end

    collection do
      get :htmlindex
      get :oldindex
    end

    member do
      get :htmlshow
      get :taskstab, as: :taskstab
      get :teamtab, as: :teamtab
    end
  end

  post '/projects/:id/save-edits', to: 'projects#saveEdit'
  post '/projects/:id/update-edits', to: 'projects#updateEdit'

  devise_for :users, :controllers => { sessions: 'sessions', registrations: 'registrations' }
  resources :users do
    member do
      get :profile
    end
  end

  resources :conversations do
    resources :messages
  end
  # also make messages available as a resource
  resources :messages

  get 'dashboard' => 'dashboard'

  #restricted mode front-view. See filter in ApplicationController and disable if no longer needed
  get 'visitors' => 'visitors#restricted'
  # root to: 'visitors#index'
  root to: 'visitors#landing'
end
