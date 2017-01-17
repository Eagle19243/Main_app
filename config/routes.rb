Rails.application.routes.draw do
  resources :group_messages, only: [:index, :create]
  post 'group_messages/get_messages_by_room'
  post 'group_messages/load_group_messages'
  post 'group_messages/users_chat'
  post 'group_messages/one_to_one_chat'
  get 'group_messages/user_messaging'
  get 'group_messages/download_files'
  get 'user_wallet_transactions/create_wallet'
  get 'pages/terms_of_use'
  get 'pages/privacy_policy'
  get 'tasks/task_fund_info'

  resources :group_messages do
    get :autocomplete_user_name, :on => :collection
  end
  get 'group_messages/search_user'
  post 'projects/send_project_invite_email'
  post 'tasks/send_email'
  post 'projects/send_project_email'
  post 'projects/start_project_by_signup'
  get 'projects/get_activities'
  get 'projects/show_all_tasks'
  get 'projects/show_all_teams'
  get 'projects/show_all_revision'
  get 'projects/show_task'
  # resources :task_attachments, only: [:index, :new, :create, :destroy]
  post 'task_attachments/create'
  post 'task_attachments/destroy_attachment'
  get 'assignments/update_collaborator_invitation_status'
  resources :profile_comments, only: [:index, :create, :update, :destroy]
  resources :plans
  resources :cards

  resources :notifications, only: [:index, :destroy] do
    collection do
      get :load_older
    end
  end

  resources :teams do
    collection do
      get :users_search
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

  resources :apply_requests, only: [:create] do
    member do
      post :accept, :reject
    end
  end

  resources :team_memberships, only: [:update, :destroy]
  resources :work_records
  get 'wallet_transactions/new'
  post 'wallet_transactions/create'
  get 'user_wallet_transactions/new'
  get 'user_wallet_transactions/download_keys'
  post 'user_wallet_transactions/create'
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

  resources :do_requests do
    member do
      get :accept, :reject
    end
  end

  resources :activities, only: [:index]
  resources :wikis
  resources :tasks do
    member do
      get :accept, :reject, :doing, :reviewing, :completed
      delete '/members/:team_membership_id', to: 'tasks#removeMember', as: :remove_task_member
    end
  end

  resources :discussions, only: [:destroy, :accept] do
    member do
      get :accept
    end
  end

  resources :favorite_projects, only: [:create, :destroy]
  resources :home , controller: 'projects'
  resources :projects, :except => [:edit] do
    resources :tasks do
      member do
        get :card_payment, to: 'payments/stripe#new'
        post :card_payment, to: 'payments/stripe#create'
      end
      resources :task_comments
      resources :assignments
    end

    resources :project_comments

    member do
      get :accept, :reject
      post :follow
      get :unfollow
      post :rate
      get :discussions
      get :revisions
      post :switch_approval_status
      get :plan
      get :read_from_mediawiki
      post :write_to_mediawiki
      get :revision_action
      get :unblock_user
      get :block_user
    end

    collection do
      get :autocomplete_user_search
      get :archived
      post :change_leader
      get :get_in
    end

    member do
      get :taskstab, as: :taskstab
      get :show_project_team, as: :show_project_team
    end
  end

  resources :change_leader_invitation, only: [:create] do
    member do
      get 'accept'
      get 'reject'
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
  get '/pages/privacy_policy'
  get '/pages/terms_of_use'

  devise_for :users, :controllers => {sessions: 'sessions', registrations: 'registrations', omniauth_callbacks: "omniauth_callbacks"}

  resources :users do
    member do
     get  :my_wallet
    end
  end

  get 'my_projects', to: 'users#my_projects', as: :my_projects
  root to: 'visitors#landing'
end
