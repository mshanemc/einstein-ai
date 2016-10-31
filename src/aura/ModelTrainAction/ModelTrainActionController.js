({
	trainThis : function(component, event, helper) {
		console.log("starting train call");

		var action = component.get("c.train");
		action.setParams({
			"modelId" : component.get("v.recordId")
		});
		console.log(action);

		action.setCallback(this, function(a){
			console.log("callback:");
			var state = a.getState();
			if (state === "SUCCESS") {
				console.log("Success!"); 
				console.log(a.getReturnValue());
				component.set("v.status", "done");
				component.set("v.modelId", a.getReturnValue());
			}  else if (state === "ERROR") {     
				console.log("Error!");               
				console.log(a.getError());
				// var appEvent = $A.get("e.c:handleCallbackError");
				// appEvent.setParams({
				// 	"errors" : a.getError()
				// });
				// appEvent.fire();
			}
		});
		$A.enqueueAction(action);
	}
})