({
	doInit : function(component, event, helper) {
		//public static string getModelDetails(string modelId){
		//console.log("record Id is " + component.get("v.recordId"));
		
		var that = this;
		
		var action3 = component.get("c.getAllModels")
		action3.setParams({ "modelId" : component.get("v.recordId")});
		action3.setCallback(this, function (a){
			//console.log(a);
			console.log(a.getReturnValue());
			if (a.getReturnValue()){
				component.set("v.models", JSON.parse(a.getReturnValue()));						
			}
		});
		$A.enqueueAction(action3);

		
	}
})