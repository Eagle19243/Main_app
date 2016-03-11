Rails.application.routes.draw do

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
  end 
  resources :project_comments

  member do
      put :accept, :reject    
    end
end
  devise_for :users, :controllers => { registrations: 'registrations' }
  resources :users

  resources :conversations do
  resources :messages
 end
 

  root to: 'visitors#index'
end
