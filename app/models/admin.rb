class Admin < CouchRestRails::Document
  use_database :podsadzacz
  devise :authenticatable, :trackable, :timeoutable, :lockable

  view_by :email, :map =>
    "function(doc){
      if (doc['couchrest-type'] == 'Admin'){
        emit(doc.email, 1)
      }
    }"
end