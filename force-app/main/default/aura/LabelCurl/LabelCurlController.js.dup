({
	doInit : function(component, event, helper) {
		var action = component.get("c.scriptHelper");
		action.setParams({
			"labelSFDCId" : component.get("v.recordId")
		});
		action.setCallback(this, function(a){
			var state = a.getState();
			if (state === "SUCCESS") {
				console.log(a);
				component.set("v.script", a.getReturnValue());
			}  else if (state === "ERROR") {   
				console.log(a.getError());                 				
			}
		});
		$A.enqueueAction(action);
		//get model name, label, id
	}
})