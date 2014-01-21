# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :lms_settings do
  collection do
    get 'generate_leave_history'
  end
  member do
    get 'start'
  end
end

resources :lms_leave_accounts, :only => [:index, :create, :update]

resources :lms_dashboards do
	
end

resources :lms_reports, :only => [:index] do
  member do
  end
  collection do
    get 'month'
    get 'ytd'
    get 'year'
  end
end
match '/lms_reports/:user_id/month_detailed/:year/:month', :via => :get, :to => 'lms_reports#month_detailed', :as => 'month_detailed_lms_report'
match '/lms_reports/:user_id/ytd_detailed/:year/:month', :via => :get, :to => 'lms_reports#ytd_detailed', :as => 'ytd_detailed_lms_report'
match '/lms_reports/:user_id/year/:year', :via => :get, :to => 'lms_reports#year_detailed', :as => 'year_detailed_lms_report'

resources :lms_leave_types do
  member do
    get 'activate'
    get 'deactivate'
  end
end
resources :lms_leaves do
  collection do
    get 'pending'
    get 'approved'
    get 'rejected'
    get 'cancelled'
    put 'deduct'
  end
  member do
    get 'approve'
    get 'reject'
    get 'proces'
  end
end
resources :lms_public_holidays