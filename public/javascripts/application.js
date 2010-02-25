function Podsadzacz(){

  this.map = new google.maps.Map(document.getElementById("map"), {
    zoom: 12,
    center: new google.maps.LatLng(50.05, 19.96),
    mapTypeId: google.maps.MapTypeId.ROADMAP
  })

  this.markers = {}

  // Open database
  try{
    this.db = window.openDatabase('Podsadzacz', 1)
  } catch(e){
    alert("Sorry. Your browser is not compatible. Please use WebKit.")
  }
}

Podsadzacz.prototype.initialize = function(){

  var that = this

  // Create stops table if doesn't exist
  if(this.db){
    this.db.transaction(
      function (transaction) {
        var sql = "CREATE TABLE IF NOT EXISTS stops (id TEXT PRIMARY KEY ON CONFLICT REPLACE, name TEXT, loc TEXT, lng REAL, lat REAL, type INTEGER)"
        transaction.executeSql(sql, [],
          function(){
            // Check for updates
            var couch = new CouchDB(that.db, 'podsadzacz_development')
            couch.pull( Cookie.get("stops") || 0, function(){
              var d = new Date()
              var month = d.getMonth() + 1
              var day = d.getDate()
              Cookie.set("stops", d.getFullYear() + "/" + ((month > 9) ? month : ("0" + month))  + "/" + ((day > 9) ? day : ("0" + day)) + " " + d.getHours() + ":" + d.getMinutes() + ":" + d.getSeconds())
              google.maps.event.trigger(that.map, 'zoom_changed')
            })
          },
          function(){
            console.log("Table 'stops' failed to create.")
          }
        )
      }
    )
  }

  google.maps.event.addListener(this.map, 'dragend', function() { // bounds_changed
    that.boundsChangedHandler()
  })

  google.maps.event.addListener(this.map, 'zoom_changed', function() { // bounds_changed
    that.boundsChangedHandler()
  })
}

Podsadzacz.prototype.boundsChangedHandler = function(){

  var markers = this.markers
  var map = this.map
  var that = this

  var zoom = map.getZoom()
  var bounds = map.getBounds()
  var ne = bounds.getNorthEast()
  var sw = bounds.getSouthWest()
  var n = ne.lat()
  var e = ne.lng()
  var s = sw.lat()
  var w = sw.lng()

  function attachInfoWindow(marker){
    google.maps.event.addListener(marker, 'click', function() {

        function lineNo(a, b){
          return a.line_no - b.line_no
        }

        var div = document.createElement("div")
        div.className = "infowindow"

        var b = document.createElement("b")
        b.innerHTML = marker.title


        var p = document.createElement("p")
        p.appendChild(b)

        if(marker.loc){
          var i = document.createElement("i")
          i.innerHTML = ", " + marker.loc
          p.appendChild(i)
        }

//        $.getJSON("/stops/timetables/" + marker.id, function(timetables){
//            $.each(timetables.sort(lineNo), function(){
//                var a = document.createElement("a")
//                a.href = "/lines/" + this.line_id + "/timetables/" + this.id
//                a.innerHTML = this.line_no
//                a.onclick = function(){
//                  showTimetable(a.href)
//                  return false
//                }
//                numbers.appendChild(a)
//            })
//        })


        $.ajax({
          url     : "/stops/"+ marker.id +"/timetables",
          dataType: "json",
          success : function(json){
            var numbers = document.createElement("div")
            numbers.className = "numbers"
            $.each(json, function(){
              var a = document.createElement("a")
              a.href = "/lines/" + this['line_id'] + "/timetables/" + this['_id']
              a.innerHTML = this.line
              $(a).click(function(){
                showTimetable(this.href)
                return false
              })
              numbers.appendChild(a)
            })
            p.appendChild(numbers)
          }
        })

        //for(j=0; j < stop.linie.length; j++){
        //  var a = document.createElement("a");
        //  a.href = "/lines/" + stop.linie[j].id + "/timetables/" + stop.linie[j].id; // !!!!!!!!!!!!!!!!!!!!!!!!
        //  a.innerHTML = stop.linie[j].no;
        //  a.onclick = function(){
        //    alert("hello");
        //    return false;
        //  }
        //  numbers.appendChild(a);
        //}

        var d = document.createElement("a")
        d.href = "/stops/" + marker.id
        d.innerHTML = "szczegóły &raquo;"
        $(d).click(function(){ that.linkToRemote(this.href); return false })

        //var d2 = document.createElement("a");
        //d2.href = "/stops/misplaced/"+ stop.id + ".ajax";
        //d2.innerHTML = "<br />zaproponuj lepszą lokalizację &raquo;"
        //d2.onclick = function(){
        //  $("#yield").load(this.href);
        //  return false;
        //}

        var rp = document.createElement("p")
        rp.className = "right"
        rp.appendChild(d)
        //rp.appendChild(d2);

        div.appendChild(p)
        div.appendChild(rp)


      // var html = marker.title + "<br /><br /><a href='/stops/" + marker.id + "'>szczegóły</a>"
      if(that.infowindow) that.infowindow.close()

      that.infowindow = new google.maps.InfoWindow({ content: div })
      that.infowindow.open(map, marker)
    })
  }

  function zoomOnClick(marker){
    google.maps.event.addListener(marker, 'click', function() {
      map.setCenter(marker.getPosition())
      map.setZoom(17)
      google.maps.event.trigger(map, 'zoom_changed')
    })
  }

  this.db.transaction(
    function (transaction) {

      var sql
      if(zoom > 14){
        // Każdy przystanek
        sql = "SELECT id,name,lng,lat FROM stops WHERE lat < ? AND lat > ? AND lng < ? AND lng > ? LIMIT 0, 200"
      } else { // if( zoom > 12){
        // Grupowanie po nazwie
        sql = "SELECT name, COUNT(*) AS count, AVG(lng) AS lng, AVG(lat) AS lat FROM stops WHERE lat < ? AND lat > ? AND lng < ? AND lng > ? GROUP BY name ORDER BY name LIMIT 0, 200"
      }
//    else {
//        // Clustering
//      }

      transaction.executeSql(sql, [n,s,e,w],
        function(transaction, result){

          console.log("select success: " + result.rows.length)
          // Dodaj tylko te które nie istnieją
          var visable = []

          try{

          for(var i=0; i < result.rows.length; i++) {
            var stop = result.rows.item(i)
            
            if(stop.count){
              stop.id = stop.name
              stop.new_name = stop.name + " (" + stop.count + " przyst.)"
            }
            visable.push(stop.id)

            if(!markers[stop.id]){
              var marker = new google.maps.Marker({
                map: map,
                id: stop.id,
                title: stop.new_name || stop.name,
                icon: '/images/point38a838.png',
                position:  new google.maps.LatLng(stop.lat, stop.lng)
              })

              if(stop.count){
                zoomOnClick(marker)
              } else {
                attachInfoWindow(marker)
              }
              markers[stop.id] = marker
            }
          }

          } catch(e){console.log(e)}

          $.each(markers, function(id, stop){
            if( visable.indexOf(id) == -1 ){
//              console.log("usuń")
              stop.setMap(null)
              delete markers[id]
            }            
          })
        },
        function(){
          console.log("Table 'stops' failed to select.")
        }
      )
    }
  )
}

Podsadzacz.prototype.linkToRemote = function(href){
  this.dumpJs()
  $("#yield").load(href)
  return false
}

Podsadzacz.prototype.dumpJs = function(){
  try{
    this.stage.cleanup()
    this.stage = null
  } catch(e){
    console.log(e)
  }

  window.Stage = null
}

Podsadzacz.prototype.loadHtml = function(){

  var that = this

  $("a.ui-state-default")
    .hover(
      function(){
        $(this).addClass("ui-state-hover")
      },
      function(){
        $(this).removeClass("ui-state-hover")
      }
    )

  $("#yield a:not(.timetable, .fg-button)").click(function(){ that.linkToRemote(this.href); return false })

//          function(){
//    that.dumpJs()
//    $("#yield").load(this.href)
//    return false
//  });

  $("#yield form")
    .attr('action', function(){ return this.action })
    .ajaxForm({target:"#yield"})

  $("#yield .datepicker").datepicker({ dateFormat: 'yy-mm-dd', duration: '' });

  if($("#yield #notice").html()) $.jGrowl($("#yield #notice").html())

  $("#yield .gchart").lightbox()

  $("ul.list > li")
    .attr("onMouseOver", "$(this).addClass('ui-state-default')")
    .attr("onMouseOut", "$(this).removeClass('ui-state-default')")
    .attr("onMouseDown", "$(this).addClass('ui-state-hover')")
    .attr("onMouseUp", "$(this).removeClass('ui-state-hover')")

  try{
    this.stage = new Stage(this)
    this.stage.setup()
  } catch(e) {
    console.log(e)
  }
}

$(function() {

  var root = new Podsadzacz()

//  $.Lightbox.construct({
//    ie6_support: false,
//    auto_relify: false,
//    show_linkback:  false,
//    show_helper_text: false,
//    show_info: true,
//    show_extended_info: true,
//    opacity: 0.6
//  })

  $("a.ui-state-default")
    .hover(
      function(){
        $(this).addClass("ui-state-hover")
      },
      function(){
        $(this).removeClass("ui-state-hover")
      }
    )

  $("a.remote").click(function(){ root.linkToRemote(this.href); return false })

  if($("#yield #notice").html()) $.jGrowl($("#yield #notice").html())

  $(document).ajaxStart(function(event, request){
//    if(opts.dataType == "html"){
//    console.log(request)
//      root.dumpJs()
//      R.dumpJs = function(){ }
//    }
    $("#load_icon").show()
  })

    .ajaxComplete(function(event, request, opts){
    if(opts.dataType == "html")
      root.loadHtml()

    $("#load_icon").fadeOut("slow")
  })

    .ajaxError(function(event, request, settings){
    $.jGrowl("Wystąpił błąd podczas ładowania strony: " + settings.url, {theme: "jGrowl-errorNotification", header:"Przepraszamy"});
  })
  
  root.initialize()
})


//function newStop(stop) {
//
//    var icon = null
//
//    if(stop.buses && stop.trams){
//        icon = point38a838_416d97
//    } else if(stop.buses){
//        icon = pointa32d2d
//    } else if(stop.trams) {
//        icon = point416d97
//    }
//
//    var marker = new GMarker(new GLatLng(stop.lng,stop.lat),{title: stop.name, icon: icon})
//
////   var marker = new google.maps.Marker({
////     position: new google.maps.LatLng(stop.lng,stop.lat),
////     map: map,
////     title: stop.name,
////     icon: point416d97
////   });
//
//    GEvent.addListener(marker, 'click', function() {
// //   google.maps.event.addListener(marker, 'click', function() {
//
//
//
//        map.openInfoWindowHtml(new GLatLng(stop.lng,stop.lat), div);
//
// //     new google.maps.InfoWindow({
// //       content: div
// //     }).open(map,marker)
//
//    });
//    return marker
//}

function openWindow(url){
  window = window.open(url, 'Timetable','width=630,height=590,toolbar=no,menubar=no,scrollbars=yes,resizable=yes,location=no,directories=no,status=no');
}

function showTimetable(timetable){
  win = window.open(timetable, 'Timetable','width=625,height=590,toolbar=no,menubar=no,scrollbars=yes,resizable=yes,location=no,directories=no,status=no');
}

// create the object
function overlaySVG(svgUrl, bounds, map) {
  this.svgUrl_ = svgUrl
  this.bounds_ = bounds
  this.map_ = map
  this.setMap(map)
}

// prototype
overlaySVG.prototype = new google.maps.OverlayView()

// initialize
overlaySVG.prototype.onAdd = function(){
  //create new div node
  var svgDiv = document.createElement("div");
  svgDiv.setAttribute( "id", "svgDivison");
  svgDiv.style.position = "absolute";
  svgDiv.style.top = 0;
  svgDiv.style.left = 0;
  svgDiv.style.height = 0;
  svgDiv.style.width = 0;
  var panes = this.getPanes();
  panes.overlayImage.appendChild(svgDiv)

  // create new svg element and set attributes
  var svgRoot = document.createElementNS( "http://www.w3.org/2000/svg", "svg")
  svgRoot.setAttribute( "id", "svgRoot")
  svgRoot.setAttribute( "width", "100%")
  svgRoot.setAttribute( "height","100%")
  svgDiv.appendChild( svgRoot)

  // keep interesting datas
  this.svgDiv_ = svgDiv

  // load the SVG file
  $.ajax({
    type: "GET",
    url: this.svgUrl_,
    dataType: "xml",
    success: function( xml ){
      // specify the svg attributes
      svgRoot.setAttribute("viewBox", xml.documentElement.getAttribute("viewBox"))
      // append the defs
      var def = xml.documentElement.getElementsByTagName("defs")
      //for( var int=0; i<def.length; i++)
      svgRoot.appendChild(def[0].cloneNode(true))
      //append the main group
      var nodes = xml.documentElement.getElementsByTagName("g")

      $.each(nodes, function(){
        svgRoot.appendChild(this.cloneNode(true))
      })
    }
  })
}

// remove from the map pane
overlaySVG.prototype.remove = function() {
  this.svgDiv_.parentNode.removeChild( this.svgDiv_ )
}

// Redraw based on the current projection and zoom level...
overlaySVG.prototype.draw = function() {
  // get the position in pixels of the bound
  var overlayProjection = this.getProjection()

  // Retrieve the southwest and northeast coordinates of this overlay
  // in latlngs and convert them to pixels coordinates.
  // We'll use these coordinates to resize the DIV.
  var sw = overlayProjection.fromLatLngToDivPixel(this.bounds_.getSouthWest())
  var ne = overlayProjection.fromLatLngToDivPixel(this.bounds_.getNorthEast())

  // Resize the image's DIV to fit the indicated dimensions.
  var div = this.svgDiv_
  div.style.left  = Math.min(sw.x, ne.x) + 'px'
  div.style.top   = Math.min(sw.y, ne.y) + 'px'
  div.style.width = Math.abs(ne.x - sw.x) + 'px'
  div.style.height= Math.abs(sw.y - ne.y) + 'px'
}