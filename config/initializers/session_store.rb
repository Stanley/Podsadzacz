# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_Podsadzacz_session',
  :secret      => '3bdbf54c698a706d4e6006a24dbd0a44a512af8deddf27ca2a0911faa8da7d5dc315b02100636da6fc39e22801d5b9f42e8eae644ccb5dcbe0974d8b6650f4f9'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
