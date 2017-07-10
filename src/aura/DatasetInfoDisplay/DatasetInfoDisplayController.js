({
	doInit : function(component, event, helper) {
		helper.fetch(component);

		let loop = window.setInterval($A.getCallback(function(){
			if (helper.shouldRetry(component)){
				helper.fetch(component);
			} else {
				stopNow();
			}
		}), 5000);

		function stopNow(){
			clearInterval(loop);
		}
	}
})