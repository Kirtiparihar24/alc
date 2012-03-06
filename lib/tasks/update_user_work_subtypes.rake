task :update_user_work_subtypes => :environment do
  role = Role.find_by_name("secretary")
  service_providers = ServiceProvider.all
  for service_provider in service_providers
    for category in role.categories
      for work_type in category.work_types
        for work_subtype in work_type.work_subtypes
          UserWorkSubtype.find_or_create_by_user_id_and_work_subtype_id(service_provider.user_id,work_subtype.id)
        end
      end
    end
  end
end