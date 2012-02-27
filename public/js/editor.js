(function () {
	var signature = window['TOKEN'] + '$$$' + window['SECRET'] + '$$$';
	var feather;
	var onFeatherLoad = function () {
		// avpw$ is jQuery
		
		/*
		 * Not sure this will remain possible but currently photo URLs
		 * are accessible by convention corresponding to image size --
		 * 2.jpg -- thumbnail
		 * 4.jpg -- full size (and hi-res URL)
		 */
		avpw$('.image-source').bind('click', function(e) {
			var url = this.src;
			url = url.replace('/2.jpg', '/4.jpg');
			// create temp full size image
			var image = avpw$('#temp-image');
			var postData = this.getAttribute('title');
			var onLoad = function() {
				feather.launch({
					image: image[0],
					url: url,
					hiresUrl: url,
					postData: signature + postData	// in case it is saved
				});
				image.unbind('load', onLoad);
			};
			image.bind('load', onLoad);
			image.attr('src', url);
			e.preventDefault();
		});
	};
	
	window.onload = function () {
		feather = new Aviary.Feather({
			
			apiKey: window['AVIARY_APIKEY'],
      apiVersion: 2,
      signature: '66396e84d2c7069a581158d1a9be5095',
			timestamp: '1318790434',
			
			postData: null,
			
			onLoad: onFeatherLoad,
			theme: 'black',
			openType: 'lightbox',
		
			//--- below are overridable at launch ---
			onSave: function(id, url) {
			
				alert(
					'Check your 500px account momentarily for a new photo with these updates!'
				);
			},		
			image: null,
			url: null,
			maxSize: 600,
			postUrl: window.location.protocol + '//' + window.location.host + '/save'
		});
		
	};

})();

