var myMarkers = {};

function enhance() {
    var myOptions = {
      zoom: 2,
      center: new google.maps.LatLng(0,0),
      mapTypeId: google.maps.MapTypeId.SATELLITE
    }
    var map = new google.maps.Map($("map_canvas"),myOptions);
    var coordinates = $$('img.mapIcon');
    for ( var i = 0; i < coordinates.length; i++ ) {
    	var coordParts = coordinates[i].title.split(',');
    	var id = coordinates[i].parentNode.parentNode.id;
		var myLatLng = new google.maps.LatLng(coordParts[0], coordParts[1]);
		var myMarker = new google.maps.Marker({
			position: myLatLng,
			map: map,
			icon: tomatoIcon,
			id: id
		});
		myMarkers[id] = myMarker;
		google.maps.event.addListener(myMarkers[id], 'click', function() {
			if (this.getAnimation() != null) {
				this.setAnimation(null);
			} 
			else {
				this.setAnimation(google.maps.Animation.BOUNCE);
			}
			if ( $(id).style.fontWeight == 'bold' ) {
				$(id).style.fontWeight = 'normal';
			}
			else {
				$(id).style.fontWeight = 'bold';
			}
		});
    }
}

function mapit(id) {
	myMarkers[id].setAnimation(google.maps.Animation.BOUNCE);
}