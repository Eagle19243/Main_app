Rails.application.routes.draw do
  match "/status/delayed_job" => DelayedJobWeb, :anchor => false, via: [:get, :post]

  if Rails.env.production?
    DelayedJobWeb.use Rack::Auth::Basic do |username, password|
      username == ENV['delayed_job_username'] && password == ENV['delayed_job_password']
    end
  end

  if Rails.env.development?
    mount MailPreview => 'mail_view'
  end

  resources :group_messages, only: [:index, :create]
  post 'group_messages/get_chatroom'
  post 'group_messages/refresh_chatroom_messages'
  get 'group_messages/download_files'
  get 'pages/terms_of_use'
  get 'pages/privacy_policy'
  get 'tasks/task_fund_info'

  resources :group_messages do
    get :autocomplete_user_username, :on => :collection
  end
  get 'group_messages/search_user'
  post 'tasks/send_email'
  post 'task_attachments/create'
  post 'task_attachments/destroy_attachment'
  resources :profile_comments, only: [:index, :create, :update, :destroy]
  resources :plans
  resources :cards

  resources :notifications, only: [:index, :destroy] do
    collection do
      put :mark_all_as_read
      get :load_older
    end
  end

  resources :teams do
    collection do
      get :users_search
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
  post 'user_wallet_transactions/send_to_any_address'
  post 'user_wallet_transactions/send_to_task_address'
  resources :proj_admins, only: [:create] do
    member do
      put :accept, :reject
    end
  end
  resources :assignments, only: [:new, :create] do
    member do
      put :accept, :reject, :completed, :confirmed, :confirmation_rejected
    end
    collection do
      put :update_collaborator_invitation_status
    end
  end

  resources :do_requests, only: [:new, :create, :destroy] do
    member do
      put :accept, :reject
    end
  end

  resources :activities, only: [:index]
  resources :wikis
  resources :tasks, only: [:show, :create, :update, :destroy] do
    member do
      put :accept, :reject, :doing, :reviewing, :completed, :refund, :incomplete
      delete '/members/:team_membership_id', to: 'tasks#removeMember', as: :remove_task_member
    end
  end

  resources :discussions, only: [:destroy] do
    member do
      put :accept
    end
  end

  resources :favorite_projects, only: [:create, :destroy]
  resources :home , controller: 'projects'
  resources :projects, :except => [:edit] do
    resources :tasks, only: [:show, :create, :update, :destroy] do
      member do
        get :card_payment, to: 'payments/stripe#new'
        post :card_payment, to: 'payments/stripe#create'
      end
      resources :task_comments, only: [:create]
      resources :assignments, only: [:new, :create]
    end

    resources :project_comments

    member do
      get :discussions, :revisions, :plan, :read_from_mediawiki, :unblock_user,
          :block_user, :taskstab, :requests, :show_project_team
      post :follow, :rate, :switch_approval_status, :write_to_mediawiki,
           :save_edits, :update_edits, :create_subpage
      put :accept, :reject, :unfollow, :revision_action
    end

    collection do
      get :get_activities, :show_all_tasks, :show_all_teams, :show_all_revision,
          :show_task, :autocomplete_user_search, :archived, :search_results,
          :get_in
      post :send_project_invite_email, :send_project_email,
           :start_project_by_signup, :user_search, :change_leader
    end
  end

  resources :change_leader_invitation, only: [] do
    member do
      put :accept, :reject
    end
  end

  get "/oauth2callback" => "projects#contacts_callback"
  get "/callback" => "projects#contacts_callback"
  get '/contacts/failure' => "projects#failure"
  get '/contacts/gmail'
  get '/contacts/yahoo'
  get '/pages/privacy_policy'
  get '/pages/terms_of_use'

  namespace :pusher do
    resources :auth, only: [:create]
    resources :chat_sessions, only: [:create]
    put 'chat_sessions/:uuid' => 'chat_sessions#update', as: :chat_session
  end

  devise_for :users, controllers: {
    sessions: 'sessions',
    registrations: 'registrations',
    omniauth_callbacks: 'omniauth_callbacks',
    confirmations: 'confirmations'
  }

  resources :users do
    member do
     get  :my_wallet
    end
  end

  namespace :api do
    namespace :v1 do
      resources :mediawiki do
        collection do
          post :page_edited
        end
      end
    end
  end


  get 'my_projects', to: 'users#my_projects', as: :my_projects
  root to: 'visitors#landing'
end
