Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :tasks, only: [ :index, :create, :update, :destroy ]
  post 'tasks/done/:id', to: 'tasks#done'

  root 'tasks#index'
end
