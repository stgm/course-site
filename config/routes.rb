CourseSite::Application.routes.draw do

	root :to => "page#homepage"
	# get "page/homepa"
	get "homepage/logout"

	post "admin/import_do"

	resources :answers

	match ":section/:page" => "page#index"

end
