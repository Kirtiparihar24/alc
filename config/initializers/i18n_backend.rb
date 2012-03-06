# Assuming redis on default localhost and port 5678

module I18nBackend
  
  def self.connect
    redis = Redis.new()
    I18n.backend = I18n::Backend::Chain.new(I18n::Backend::KeyValue.new(redis), I18n.backend)

  end
end

if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked
      # We're in smart spawning mode. If we're not, we do not need to do anything
       I18nBackend.connect
    end
  end
else
I18nBackend.connect
end
#TRANSLATION_STORE = Redis.new

#I18n.backend =I18n::Backend::KeyValue.new(TRANSLATION_STORE)
#I18n.backend = I18n::Backend::Chain.new(I18n::Backend::KeyValue.new(TRANSLATION_STORE), I18n.backend)
