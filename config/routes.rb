Rails.application.routes.draw do
  # exercise: RESTful API endpoint that returns a paginated JSON
  # list of rides in descending score order for a given driver
  resources :drivers do
    # driver_ride, GET, /drivers/:driver_id/rides/:id, rides#show
    resources :rides, only: [:index]
  end

  # default routes for RESTfulness and data setup, but not the focus
  # of this exercise.
  resources :drivers
  resources :rides
  resources :addresses

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
