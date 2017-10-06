Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "api/secret_1", to: "api#secret_1"
  get "api/secret_2", to: "api#secret_2"
end
