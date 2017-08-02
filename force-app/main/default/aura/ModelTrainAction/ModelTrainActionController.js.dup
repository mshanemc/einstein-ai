({
	setDefaultRetrain : function(component) {
		if (component.get("v.fieldsv").Einstein_Model_Id__c || component.get("v.fieldsv").Einstein_Trained_Model_Id__c ){
			component.set("v.hasModelId", true);
			component.set("v.retrain", true);
		}
		if (component.get("v.fieldsv").EinsteinID__c || component.get("v.fieldsv").Einstein_Dataset_Id__c){
			component.set("v.hasDatasetId", true);
		}
	},

	trainThis : function(component) {
		console.log("starting train call");

		let action = component.get("c.train");

		action.setParams({
			"modelId" : component.get("v.recordId"),
			"epochs" : component.get("v.epochs") || null,
			"retrain" : component.get("v.retrain")
		});
		console.log(action);

		action.setCallback(this, function(a){
			console.log("callback:");
			var state = a.getState();
			if (state === "SUCCESS") {
				console.log("Success!");
				console.log(a.getReturnValue());
				$A.get("e.force:showToast").setParams({
					"type" : "success",
					"message" : "Your model is now training.  The modelId is " +a.getReturnValue()+" and it's now saved to the record."
				}).fire();
				$A.get("e.ltng:sendMessage").setParams({
					"message" : component.get("v.recordId"),
					"channel" : "modelTrain"
				}).fire();
				$A.get("e.force:refreshView").fire();
				$A.get("e.force:closeQuickAction").fire();
			}  else if (state === "ERROR") {
				component.find("leh").passErrors(a.getError());
			}
		});
		$A.enqueueAction(action);
	}
})