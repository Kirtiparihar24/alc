ActionController::Routing::Routes.draw do |map|
  #map.resources :user_tasks
  #  map.with_options(:path_prefix => "wfm") do |m|
  #    m.resources :user_tasks
  #    #m.resources :stories
  #  end
  map.namespace 'wfm' do |wfm|
    wfm.resources :notifications, :collection =>{:more_notifications => :get}
    wfm.resources :user_tasks,
      :member=>{:document_history=>:get, :download_document=>:get,:supercede_document=>:get,
                :reassign_task=>:get, :task_histroy => :get, :reassign_this_task => :post, :complete_this_task => :put,:get_lawyer_info => :post},
      :collection=>{:get_next_task=>:get,:reassign_multiple_task_form=>:get,:reassign_multiple_tasks=>:post, :import_task_by_file => :get,:create_import_task_by_file=> :post,:download_xls_format=> :get}
    wfm.new_documents '/user_tasks/new_documents/:task_id', :controller => 'user_tasks', :action => 'new_documents'
    wfm.upload_documents '/user_tasks/upload_documents', :controller => 'user_tasks', :action => 'upload_documents'
    wfm.complete_task '/user_tasks/complete_task/:id', :controller => 'user_tasks', :action => 'complete_task', :method=>:get
    wfm.filter_tasks "/user_tasks/filter_tasks/:option", :controller => 'user_tasks', :action => "filter_tasks", :method=>:get, :option => /[\w|-]*/
    wfm.filter_tasks "/notes/get_lawfirm_and_lawyers", :controller => 'notes', :action => "get_lawfirm_and_lawyers"
    wfm.open_recurring_task '/user_tasks/open_recurring_task/:id', :controller => 'user_tasks', :action => 'open_recurring_task', :method=>:get
    wfm.resources :comments
    wfm.resources :notes, :member=>{:complete_note=>:get,:do_complete_note=>:post,:assign_note_form=>:get, :assign_note=>:post, :assign_this_note=>:put,:allow_lock=>:post},
      :collection=>{:get_lawfirm_and_lawyers=>:get,:assign_multiple_notes_form=>:get,:assign_multiple_notes=>:post}
    wfm.resources :user_work_subtypes, :collection=>{:getUserSkills => :get,:update_user_skills=>:post,
      :get_clusters_livians_and_skills_for_selected_lawyer=>:get,:get_livians_and_skills=>:get,
      :get_livians_skills=>:get, :update_skills=>:get, :update_livian_skills=>:get, :skills_by_livians=>:get, :skills_by_backoffice_agents=>:get}
    wfm.filter_notes "/notes/filter_notes/:option", :controller => 'notes', :action => "filter_notes", :method=>:get, :option => /[\w|-]*/

    wfm.filter_lawyer "/user_tasks/filter_lawyer/:id", :controller => 'user_tasks', :action => 'filter_lawyer', :method=>:get
    wfm.filter_priority "/user_tasks/filter_priority/:id", :controller => 'user_tasks', :action => 'filter_priority', :method=>:get
    wfm.filter_work_subtype "/user_tasks/filter_work_subtype/:id", :controller => 'user_tasks', :action => 'filter_work_subtype', :method=>:get
    wfm.filter_assigned_to "/user_tasks/filter_assigned_to/:id", :controller => 'user_tasks', :action => 'filter_assigned_to', :method=>:get
    wfm.filter_cluster "/user_tasks/filter_cluster/:id", :controller => 'user_tasks', :action => 'filter_cluster', :method=>:get
    wfm.manage_priorities "/manage_clusters/manage_priorities", :controller => 'manage_clusters', :action => "manage_priorities"

    wfm.resources :manage_clusters, :member => {:edit_temp_assignment => :get, :update_temp_assignment => :put}

    wfm.lawyer_list "/secretaries/lawyer_list", :controller => "secretaries", :action => 'lawyer_list'

    wfm.resources :document_homes 
    wfm.new_document_home "/document_homes/new_document_home/:mapable_type/:mapable_id", :controller => 'document_homes', :action => 'new_document_home', :method=>:any
    
  end
  
  map.devise_for :users, :path_names => { :sign_in => 'login', :sign_out => 'logout' }


  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  #  map.connect ':controller/:action/:id'
  #  map.connect ':controller/:action/:id.:format'
end
