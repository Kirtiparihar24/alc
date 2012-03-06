ActionController::Routing::Routes.draw do |map|
  map.resources :tne_invoice_details

  map.resources :tne_invoices, :collection => {:display_data => :post,:search_invoice => :get, :view_unbilled_entries => :get,:preview_bill => :get,:check_invoice_no => :get,:get_matter_no => :get}, :member => {:change_status => :get, :regenerate_bill => [:get], :regenerate => :get}
   map.select_manual_or_system_bill "select_manual_or_system_bill", :controller => "tne_invoices", :action=>"select_manual_or_system_bill"
  map.delete_time_entry "delete_time_entry", :controller => "tne_invoice_time_entries", :action=>"delete_time_entry"
  map.delete_expense_entry "delete_expense_entry", :controller => "tne_invoice_expense_entries", :action=>"delete_expense_entry"
  map.new_time_entry "new_time_entry",:controller =>"tne_invoice_time_entries",:action =>"new_time_entry"
  map.new_expense_entry "new_expense_entry",:controller =>"tne_invoice_expense_entries",:action =>"new_expense_entry"
  map.resources :tne_invoice_settings
  map.resources :tne_invoice_time_entries,:member=> {:set_time_entry_description=>:post,
    :poc => :get,
      :set_time_entry_actual_duration => :post,
      :set_time_entry_formatted_start_time => :post,
      :set_time_entry_formatted_end_time => :post,
      :set_time_entry_actual_bill_rate => :post,
      :set_time_entry_billing_amount => :post,
      :set_time_entry_full_amount =>:post,
      :set_time_entry_billing_percent => :post,      
      :set_is_billable => :post
  },:collection => {
    :add_new_time_entry => :get,
    :delete_all_time_entries => :get
    
  }
#  , :collection => {:set_time_entry_billing_percent => :get,:set_time_entry_billing_amount => :get}
  map.set_time_entry_actual_duration "set_time_entry_actual_duration",:controller =>"tne_invoice_time_entries",:action =>"set_time_entry_actual_duration"  
  map.resources :tne_invoice_expense_entries,:member=> {:set_expense_entry_description=>:post,
      :set_expense_entry_expense_amount => :post,
      :set_expense_entry_billing_percent => :post,
      :set_expense_entry_billing_amount => :post,
      :set_expense_entry_full_amount =>:post,
      :save_all_expense_entries_home=>:post,
      :set_expense_entry_markup =>:post     
  },:collection => {
    :add_new_expense_entry => :get,
    :delete_all_expense_entries => :get
    

  }

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
   #map.root :controller => "tne_invoices"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  #map.connect ':controller/:action/:id'
  #map.connect ':controller/:action/:id.:format'
end
