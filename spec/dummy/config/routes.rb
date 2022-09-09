Rails.application.routes.draw do
  root to: 'users#index'

  resources :users, only: %i[index]
end
