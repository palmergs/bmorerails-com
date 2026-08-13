Rails.application.routes.draw do
  root "pages#home"

  get "code-of-conduct" => "pages#code_of_conduct", as: :code_of_conduct

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
