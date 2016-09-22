Rails.application.routes.draw do
  get 'chat_rooms/create_room'
  get 'assignments/update_collaborator_invitation_status'
  resources :profile_comments, only: [:index, :create, :update, :destroy]
  resources :plans
  resources :notifications
  resources :cards

  resources :teams
  get 'projects/:project_id/team_memberships', to: 'teams#team_memberships'
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

  resources :discussions, only: [:destroy, :accept] do
    member do
      get :accept
    end
  end

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
      get :discussions
    end

    collection do
      get :autocomplete_user_search
    end

    member do
      get :taskstab, as: :taskstab
      get :teamtab, as: :teamtab
    end
  end

  get '/projects/search_results', to: 'projects#search_results'
  post '/projects/user_search', to: 'projects#user_search'
  post '/projects/:id/save-edits', to: 'projects#saveEdit'
  post '/projects/:id/update-edits', to: 'projects#updateEdit'

  devise_for :users, :controllers => { sessions: 'sessions', registrations: 'registrations', omniauth_callbacks: "omniauth_callbacks"  }

  resources :users
  resources :messages

  get 'my_projects', to: 'users#my_projects', as: :my_projects
  #restricted mode front-view. See filter in ApplicationController and disable if no longer needed
  get 'visitors' => 'visitors#restricted'

  # root to: 'visitors#landing'
  # show active projects as the landing page
  root to: 'projects#index'
end