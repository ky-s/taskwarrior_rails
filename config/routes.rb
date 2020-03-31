Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  resources :tasks, only: [ :index, :create, :edit, :update, :destroy ]
  post 'tasks/done/:id', to: 'tasks#done'
  post 'tasks/redue', to: 'tasks#redue'

  root 'tasks#index'
end
