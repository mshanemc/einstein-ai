({
	handleMessage : function(component, event) {
		//don't care about extraneous noise
		if (event.getParam("channel") === 'streamingAPISubscriber' && (event.getParam("message").data.payload.RecordId__c === component.get("v.recordId") || event.getParam("message").data.payload.liveRecord__RecordId__c === component.get("v.recordId"))){
			if (component.get("v.log")){
				console.log(event.getParam("message"));
			}

			if (component.get("v.autoRefresh")){
				$A.get("e.force:refreshView").fire();
			}
			if (component.get("v.autoToast")){
				let toast = $A.get("e.force:showToast");
				if (component.get("v.autoRefresh")){
					toast.setParams({"message" : "The record was just updated.  The page just refreshed with the latest data."});
				} else {
					toast.setParams({"message" : "The record was just updated.  Refresh the page to see the latest data."});
				}
				toast.fire();
			}

		} else {
			if (component.get("v.log")){
				console.log("don't care about this message");
			}
		}
	}
})