mapboxgl.accessToken = 'pk.eyJ1IjoicGV0ZXJxbGl1IiwiYSI6ImpvZmV0UEEifQ._D4bRmVcGfJvo1wjuOpA1g';

var map = new mapboxgl.Map({
  container: 'map',
  style: 'mapbox://styles/peterqliu/ciug032my008f2ipm1z1rf15q',
  center: [-99.9, 31.9],
  zoom: 5,
  minZoom: 11,
  maxZoom: 17,
  maxBounds: [[-120, 10], [-80, 40]]
});

  var emptyGeojson = {
    "type": "FeatureCollection",
    "features": []
  };
  map.on('load', function(){

    //set up data sources
    map.addSource('population', {
      'type':'vector',
      'url':'mapbox://peterqliu.d0vin3el'
    })


    //set up data layers
    map
    .addLayer({
      'id':'fills',
      'type':'fill',
      'filter':['all', ['<', 'pkm2', 300000]],
      'source':'population',
      'source-layer':'outgeojson',
      'paint':{
        'fill-color':{"stops": [[0,'#160e23'],[14500,'#00617f'], [145000,'#55e9ff']], "property": "pkm2", "base": 1},
        'fill-opacity':1
      },
      'paint.tilted':{
      }
    }, 'water')
    
  });

    // sync map to legend
