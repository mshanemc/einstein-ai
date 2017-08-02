({
	doInit : function(component, event, helper) {
		if (event.getParam("channel") && event.getParam("channel")!=='datasetCreation'){
			return;
		} else if (event.getParam("message") && event.getParam("message")!==component.get("v.recordId")){
			return;
		}
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