function keepalive() {
	$.ajax({
	   type: "GET",
	   url: "/profile/ping"
	 }); 
	setTimeout(function(){
		keepalive();
	}, 1800000);
}

$(document).ready(function() {
	setTimeout(function(){
		keepalive();
	}, 1800000);
});

