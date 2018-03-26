// Borrowed from:
// https://bl.ocks.org/kmandov/70be1f3b2648ad2be1cdf1feb5afbb4d

// Mapbox
mapboxgl.accessToken = 'pk.eyJ1IjoidGV4YXN0cmlidW5lIiwiYSI6Ilo2eDhZWmcifQ.19qcXfOTN6ulkGW5oouiPQ'

var map = new mapboxgl.Map({
  container: 'map',
  center: [-97.7, 30.2],
  style: 'mapbox://styles/texastribune/cj5wvyfqn2uwv2rs06crlojs8',
  zoom: 5,
  minZoom: 5,
  maxZoom: 17,
  maxBounds: [[-120, 10], [-80, 40]]
});

// Disable map rotation on mobile, desktop
map.dragRotate.disable();
map.touchZoomRotate.disableRotation();

// SVG
var container = map.getCanvasContainer(),
  svg = d3.select(container).append('svg'),
  feature_element = [],
  feature_element_keys = [],
  point,
  transform = d3.geoTransform({point: projectPoint});

var path = d3.geoPath()
  .projection(transform);

map.on('move', function(e){
  var current_zoom = map.getZoom();

  update(current_zoom);
});

// Update the path using the current transform
function update(zoom) {
  for (var num = 0; num < feature_element_keys.length; num++) {
    c_key = feature_element_keys[num];

    feature_element[c_key].attr('d', path);
  }
}

// Align Mapbox with D3
function projectPoint(long, lat) {
  point = map.project(new mapboxgl.LngLat(long, lat));
  
  this.stream.point(point.x, point.y);
}

// Draw shapes on map using D3
function drawMaps(file){
  var url = 'topojson/' + file + '.topojson';
  if (file.indexOf('all_') > -1) {
    var shp_obj = 'Texas_US_House_Districts';
  } else {
    var shp_obj = file;
  }

  feature_element_keys.push(file);

  d3.json(url, function(error, features) {
    // Use data to draw shapes
    var data = topojson.feature(features, features.objects[shp_obj])
    var features = data.features;

    feature_element[file] = svg.selectAll('path')
      .data(features)
      .enter()
        .append('path')
        .attr('d', path)
        .attr('class', function(d) { 
          if (file.indexOf('all_') > -1) {
            if (d.properties['DIST_NBR'] != undefined) {
              var dist_num = d.properties['DIST_NBR']
            } else {
              var dist_num = d.properties['CD115FP']
            }

            return 'district district-' + dist_num;
          } else {
            return 'road';
          }
        });
  // close d3 json
  });

// close drawMaps 
}

// Load everything else
map.on('load', function () {
  map.addSource('all-but-tx', {
    type: 'geojson',
    'data': geo_all_but_tx
  });

  map.addLayer({
    'id': 'layer-all-but-tx',
    'type': 'fill',
    'source': 'all-but-tx',
    'layout': {},
    'paint': {
      'fill-color': '#FFF',
      'fill-opacity': 1
    }
  });

  // Drop it like it's hot
  drawMaps('all_current');

  document.getElementById('map').style.visibility = 'visible'
  
// close map on load
});