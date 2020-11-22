function keepalive() {
	Rails.ajax({
	   type: "GET",
	   url: "/profile/ping"
	 }); 
	setTimeout(function(){
		keepalive();
	}, 1800000);
}

document.addEventListener('ready', function() {
	setTimeout(function(){
		keepalive();
	}, 1800000);
});
