var hash;

var zoom_points = {
  '2': {
    'center': [-97.7, 30],
    'scale': 18
  },
  '3': {
    'center': [-97.7, 30],
    'scale': 16
  }
};

// Zoom to point corresponding with hash number
function zoomTo(hash_num) {
  var point = projection(zoom_points[hash_num]['center']);

  svg.transition()
    .delay(250)
    .duration(2000)
    .call(
      zoom.transform, d3.zoomIdentity
        .translate(width / 2, height / 2)
        .scale(1 << zoom_points[hash_num]['scale'])
        .translate(-point[0], -point[1])
    );
}

function hashChange() {
  // Change hash
  hash = window.location.hash.replace('#','');
  
  // Zoom to point
  zoomTo(hash)
}

window.onhashchange = hashChange