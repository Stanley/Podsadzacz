// OBJECT

CouchDB.failureHandler = function(XMLHttpRequest, textStatus, errorThrown){
//  console.log(XMLHttpRequest)
//  Mojo.Controller.getAppController().showBanner("Wystąpił błąd przy połączeniu ze zdalną bazą danych.", {source: 'notification'})

  console.log("błąd couchdb")
}

// CLASS

function CouchDB(db, name) {

  this.db = db
  this.name = name
  this.server = "http://localhost:5984/"
  this.uri = this.server + this.name

}

// GET a document from CouchDB, by id. Returns an Object.
CouchDB.prototype.get = function(id){


  $.ajax({
    url     :  uri +"/"+ id,
    type    : "GET",
    dataType: "jsonp",
    success : function(doc){ console.log("couch get success") },
    error   : CouchDB.failureHandler
  })  
}

// GET changes between local and remote databases
// and GET each document
// and save them in local db
CouchDB.prototype.pull = function(rev, callback){

  var db = this.db
  var uri = this.uri
  var couch = this

  $.ajax({
    url     : uri + "/_design/Stop/_view/by_updated_at?startkey=[\"" + rev + "\"]",
    type    : "GET",
    dataType: "jsonp",
    success : function(json){
      console.log(uri + "/_design/Stop/_view/by_updated_at?startkey=[" + rev + "]")
      // TODO: DB Error handling
      couch.bulk_save(db, json.rows, callback)
    },
    error   : CouchDB.failureHandler
  })
}

CouchDB.prototype.bulk_save = function(db, rows, callback){
  var couch = this
  db.transaction(
    function(transaction){
      $.each(rows, function(){
        var doc = this.value
        doc.id = this.id
        transaction.executeSql("INSERT INTO stops (id, name, loc, lng, lat, type) VALUES (?, ?, ?, ?, ?, ?)", [doc.id, doc.n, doc.l, doc.lng, doc.lat, doc.t],
          function(){
            console.log("insert / update sukces")
          },
          couch.handleSqlError
        )
      })
    },
    function(){ console.log("failure") },
    callback
  )
}

// This prototype should not exist
CouchDB.prototype.handleSqlError = function(transaction, error){
  console.log("An SQL Error occured: " + error.message)
}

CouchDB.prototype.authenticate = function(login, password){
  
}
