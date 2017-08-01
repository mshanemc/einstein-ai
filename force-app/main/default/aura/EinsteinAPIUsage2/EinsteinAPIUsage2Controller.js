({
	doInit : function(component, event, helper) {
		let action = component.get("c.getAPIusage");
		action.setCallback(this, function(a){
			let state = a.getState();
			if (state === "SUCCESS") {
				console.log(JSON.parse(a.getReturnValue()));
				component.set("v.usage", JSON.parse(a.getReturnValue()).data);
			}  else if (state === "ERROR") {
				component.find("leh").passErrors(a.getError());
			}
		});
		$A.enqueueAction(action);
	}
})