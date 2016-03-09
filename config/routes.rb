Rails.application.routes.draw do
  get 'activities/index'
  resources :activities, only: [:index]
  resources :wikis
  resources :tasks
  resources :projects do
  resources :tasks do
  	resources :task_comments
  end 
  resources :project_comments

  member do
      get :accept, :reject    
    end
end
  devise_for :users, :controllers => { registrations: 'registrations' }
  resources :users

  resources :conversations do
  resources :messages
 end
 

  root to: 'visitors#index'
end
