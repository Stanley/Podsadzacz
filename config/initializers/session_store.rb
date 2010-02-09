# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_Podsadzacz_session',
  :secret => 'ef39c2a145e9222b858659404091a18cb94c3bc5f7bd5880e1974cb2be3830f81ceebbe172b0f2c7ed91236f207d5c09faf6db00bcd13b80fbed2920f1b5e786'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
