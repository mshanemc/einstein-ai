({
	doInit : function(component, event, helper) {
		console.log("DatasetModelList is in Init");
		//gets and updates the UI in the background
		helper.getModels(component);
		//wait 5 seconds, and if there are any RUNNING/QUEUED, do it again

		let loop = window.setInterval($A.getCallback(function(){
			if (helper.shouldRetry(component)){
				console.log("shouldRetry returned true")
				helper.getModels(component);
			} else {
				console.log("shouldRetry returned false")
				stopNow();
			}
		}), 5000);

		function stopNow(){
			console.log("in stopNow");
			clearInterval(loop);
		}
	}

})