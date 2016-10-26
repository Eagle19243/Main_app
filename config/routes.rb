Rails.application.routes.draw do
  # get 'task_attachments/index'
  #
  # get 'task_attachments/new'
  #
  # get 'task_attachments/create'
  #
  post 'projects/send_project_invite_email'
  post 'tasks/send_email'
  post 'projects/send_project_email'
  get 'teams/remove_membership'
  get 'projects/show_task'
 # resources :task_attachments, only: [:index, :new, :create, :destroy]
  post 'task_attachments/create'
  post 'task_attachments/destroy_attachment'
  get 'chat_rooms/create_room'
  get 'assignments/update_collaborator_invitation_status'
  resources :profile_comments, only: [:index, :create, :update, :destroy]
  resources :plans
  resources :notifications, only: [:index]
  resources :cards

  resources :teams do
    collection do
      get :users_search
    end

    member do
      get :apply_as_admin
    end
  end

  resources :admin_invitations, only: [:create] do
    member do
      post :accept, :reject
    end
  end

  resources :admin_requests, only: [:create] do
    member do
      post :accept, :reject
    end
  end

  get 'projects/:project_id/team_memberships', to: 'teams#team_memberships'
  resources :team_memberships
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
  resources :do_requests do
    member do
      get :accept, :reject
    end
  end

  resources :activities, only: [:index]
  resources :wikis
  resources :tasks do
    member do
      get :accept, :reject, :doing,:reviewing,:completed
    end
  end

  resources :discussions, only: [:destroy, :accept] do
    member do
      get :accept
    end
  end

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
      get :discussions
    end

    collection do
      get :autocomplete_user_search
    end

    member do
      get :taskstab, as: :taskstab
      get :show_project_team, as: :show_project_team
    end
  end

  get '/projects/search_results', to: 'projects#search_results'
  post '/projects/user_search', to: 'projects#user_search'
  post '/projects/:id/save-edits', to: 'projects#saveEdit'
  post '/projects/:id/update-edits', to: 'projects#updateEdit'

  get "/oauth2callback" => "projects#contacts_callback"
  get "/callback" => "projects#contacts_callback"
   get '/contacts/failure' => "projects#failure"
  get '/contacts/gmail'
  get '/contacts/yahoo'

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