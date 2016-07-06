Rails.application.routes.draw do
  resources :work_records
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
  end

  post '/projects/:id/save-edits', to: 'projects#saveEdit'
  post '/projects/:id/update-edits', to: 'projects#updateEdit'

  devise_for :users, :controllers => { sessions: 'sessions', registrations: 'registrations' }
  resources :users

  resources :conversations do
    resources :messages
  end

  get 'dashboard' => 'dashboard'

  #restricted mode front-view. See filter in ApplicationController and disable if no longer needed
  get 'visitors' => 'visitors#restricted'
  root to: 'visitors#index'
end
