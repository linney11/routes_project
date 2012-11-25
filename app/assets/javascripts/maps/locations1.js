try{
var map;
var selectControl;

var SHADOW_Z_INDEX = 10;
var MARKER_Z_INDEX = 11;

function initMap(locations1) {
    map = new OpenLayers.Map("map");
    var mapnik = new OpenLayers.Layer.OSM();
    var bing = new OpenLayers.Layer.Bing({
        key: "AvMWbfAOLj7TwpafrYzZliDCtn2rjVhfErn_kE5fO2QS0FBmx0ujfB3449IZMY46", //Get your API key at https://www.bingmapsportal.com
        type: "Aerial"
    });
    var fromProjection = new OpenLayers.Projection("EPSG:4326"); // Transform from WGS 1984
    var toProjection = new OpenLayers.Projection("EPSG:900913"); // to Spherical Mercator Projection
    var position = new OpenLayers.LonLat(-116.60520, 31.86648).transform(fromProjection, toProjection); //Ensenada, BC, MX
    var zoom = 14;

    map.addLayers([mapnik, bing]);
    map.setBaseLayer(mapnik);
    map.addControl(new OpenLayers.Control.LayerSwitcher());
    map.addControl(new OpenLayers.Control.MousePosition({
        displayProjection: "EPSG:4326"
    }));
    map.setCenter(position, zoom);

    var locations = eval (locations1)
    for (var i=0; i<locations.length; i++){
    var locationsJSON = eval(locations[i]);

    //todo: use reviver function?
//    var locationsJSON = JSON.parse(locations, reviver);

  /*  var styles = new OpenLayers.StyleMap({
        "default": new OpenLayers.Style(OpenLayers.Util.applyDefaults({
            externalGraphic: '/assets/maps/img/blue-bus.png',
            backgroundGraphic: "/assets/maps/icons/balloon-shadow.png",
            graphicZIndex: MARKER_Z_INDEX,
            backgroundGraphicZIndex: SHADOW_Z_INDEX,
            backgroundXOffset: -7,
            backgroundYOffset: -32,
            graphicHeight: 32,
            fillOpacity: 1,
            graphicYOffset: -32
        }, OpenLayers.Feature.Vector.style["default"])),
        "select": new OpenLayers.Style({
            externalGraphic: '/assets/maps/img/red-bus.png'
        })
    });

    var locationsLayer = new OpenLayers.Layer.Vector("Locations", {styleMap: styles});
    map.addLayer(locationsLayer);

    for (var location in locationsJSON) {

        var locationPosition = new OpenLayers.LonLat(locationsJSON[location].longitude, locationsJSON[location].latitude).transform(fromProjection, toProjection);
        var datetimestamp=locationsJSON[location].timestamp
        //var dateconverted=new Date(datetimestamp).format('h:i:s')
        var dateconverted= timeConverter(datetimestamp)
        var locationMarker = new OpenLayers.Feature.Vector(
            new OpenLayers.Geometry.Point(locationPosition.lon, locationPosition.lat), {
                title: locationsJSON[location].name+"<br/>"+ locationsJSON[location].message ,
                description:locationsJSON[location].answer + " <br/>" +dateconverted

               // description: locationsJSON[location].description
               // timeConverter(timestamp)
                //new Date(timestamp).format('h:i:s')
            }
        );

        locationsLayer.addFeatures(locationMarker);

    }

    selectControl = new OpenLayers.Control.SelectFeature(
        locationsLayer,
        {
            clickout: true,
            toggle: false,
            multiple: false,
            hover: false,
            toggleKey: "ctrlKey", // ctrl key removes from selection
            multipleKey: "shiftKey" // shift key adds to selection
        }
    );
    map.addControl(selectControl);
    selectControl.activate();
    locationsLayer.events.on({
        'featureselected': onFeatureSelect,
        'featureunselected': onFeatureUnselect
    }); */

//Empieza lo de pintar una linea con diversas coordenadas
    var lineLayer = new OpenLayers.Layer.Vector("Line Layer");

    map.addLayer(lineLayer);
    map.addControl(new OpenLayers.Control.DrawFeature(lineLayer, OpenLayers.Handler.Path));

    //// acomodar esto para agregar los puntos en una variable point

    var points = new Array();
    for (var loc in locationsJSON) {
        var locationPosition2 = new OpenLayers.LonLat(locationsJSON[loc].longitude, locationsJSON[loc].latitude).transform(fromProjection, toProjection);
        points.push(
            new OpenLayers.Geometry.Point(locationPosition2.lon, locationPosition2.lat)
        );

       // player.push(new user("Main Player", 1, 1, "naked"));

      //  locationsLayer.addFeatures(locationMarker);
    }

    ////

  //  var points = new Array(
    //    new OpenLayers.Geometry.Point(lon1, lat1),
      //  new OpenLayers.Geometry.Point(lon2, lat2)
    //);

    var line = new OpenLayers.Geometry.LineString(points);

    var style = {
        strokeColor:get_random_color(),
        strokeOpacity: 1,
        strokeWidth: 5
    };

    var lineFeature = new OpenLayers.Feature.Vector(line, null, style);
    lineLayer.addFeatures([lineFeature]);
}
}

    function get_random_color() {
        var letters = '0123456789ABCDEF'.split('');
        var color = '#';
        for (var i = 0; i < 6; i++ ) {
            color += letters[Math.round(Math.random() * 15)];
        }
        return color;
    }

function timeConverter(timestamp){
    var a = new Date(timestamp);
    var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    var year = a.getFullYear();
    var month = months[a.getMonth()];
    var date = a.getDate();
    var hour = a.getHours();
    var min = a.getMinutes();
    var sec = a.getSeconds();
    var time = date+','+month+' '+year+' '+hour+':'+min+':'+sec ;
    return time;
}

function addMarker(layer, markerPosition, popupClass, popupContentHTML, closeBox, overflow) {
    var feature = new OpenLayers.Feature(layer, markerPosition);
    feature.closeBox = closeBox;
    feature.popupClass = popupClass;
    feature.data.popupContentHTML = popupContentHTML;
    feature.data.overflow = (overflow) ? "auto" : "hidden";

    var marker = feature.createMarker();

    var markerClick = function (evt) {
        if (this.popup == null) {
            this.popup = this.createPopup(this.closeBox);
            map.addPopup(this.popup);
            this.popup.show();
        } else {
            this.popup.toggle();
        }
        currentPopup = this.popup;
        OpenLayers.Event.stop(evt);
    };
    marker.events.register("mousedown", feature, markerClick);

    layer.addFeatures(marker);
}


function onPopupClose(evt) {
    // 'this' is the popup.
    var feature = this.feature;
    if (feature.layer) { // The feature is not destroyed
        selectControl.unselect(feature);
    } else { // After "moveend" or "refresh" events on POIs layer all
        // features have been destroyed by the Strategy.BBOX
        this.destroy();
    }
}
function onFeatureSelect(evt) {
    feature = evt.feature;
    popup = new OpenLayers.Popup.FramedCloud(
        "featurePopup",
        feature.geometry.getBounds().getCenterLonLat(),
        null,
        "<h1>"+feature.attributes.title + "</h1>" + feature.attributes.description,
        null,
        true,
        onPopupClose
    );
    feature.popup = popup;
    popup.feature = feature;
    map.addPopup(popup, true);
}
function onFeatureUnselect(evt) {
    feature = evt.feature;
    if (feature.popup) {
        popup.feature = null;
        map.removePopup(feature.popup);
        feature.popup.destroy();
        feature.popup = null;
    }
}
}catch (x){
alert (x)}