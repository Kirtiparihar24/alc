# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_billing_solutions_session',
  :secret      => '94282bc2977dfa068647c7faf01b3bcc0831af8cbff664c51cd937e30cb68bf997475e4d594d8b452c6941ad217e5c0a1198bfd9e66578338eafdba7fd16e9ee'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
