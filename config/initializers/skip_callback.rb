class ActiveRecord::Base
  # added by sanil - 2nd july
  # warning do not overuse
  # this methods extends active record to allow you to skip callbacks(e.g before_save,after_save.etc) for transactions
  #usage - Model.skip_callback(:name_of_callback) do
  #--- code----
  #end
    def self.skip_callback(callback, &block)
    method = instance_method(callback)
    remove_method(callback) if respond_to?(callback)
    define_method(callback) { true }
    yield
    remove_method(callback)
    define_method(callback, method)
  end
end