({
	doInit : function(component, event, helper) {
		let tokenAction = component.get("c.getAccessToken");
		helper.executeAction(component, tokenAction)
			.then($A.getCallback(function (token){
				console.log(token);
				component.set("v.token", token);
			}), $A.getCallback(function(){}));
	}
})