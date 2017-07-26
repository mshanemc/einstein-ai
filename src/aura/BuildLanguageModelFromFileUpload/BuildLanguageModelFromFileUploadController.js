({
	doInit : function(component, event, helper) {
		//	public static string getFileOptions(id recordId){
		let action = component.get("c.getFileOptions");
		action.setParams({
			"recordId" : component.get("v.recordId")
		});
		let prom = helper.executeActionJSON(component, action)
			.then($A.getCallback(function (result){
				console.log(result);
				component.set("v.files", result);
			}), $A.getCallback(function(){}));
	},

	previewFile : function(component) {
		$A.get('e.lightning:openFiles').fire({
      recordIds: [component.get("v.selectedFile")]
		});
	},

	makeModel : function(component, event, helper) {
		//create the distribution for that file
		//	public static string createDatasetFromAttachedFile(id CVid, string SFDCmodelId){
		let makeCDist = component.get("c.createCDistFromAttachedFile");
		let version;
		for (let file of component.get("v.files")){
			if (component.get("v.selectedFile") === file.ContentDocumentId){
				version = file.ContentDocument.LatestPublishedVersionId;
			}
		}
		makeCDist.setParams({
			"CVid" : version
		});
		let prom = helper.executeActionJSON(component, makeCDist)
			.then($A.getCallback(function (result){
				console.log(result);
				let doModel = component.get("c.createDatasetPart2");
				doModel.setParams({
					"SFDCmodelId" : component.get("v.recordId"),
					"CDID" : result.Id
				});
				return helper.executeActionJSON(component, doModel);
			}))
			.then($A.getCallback(function (result){
				console.log(result);
				if (result.id){
					component.set("v.fields.Einstein_Dataset_Id__c", result.id.toString());
					component.find("frd").saveRecord(
						$A.getCallback(function(saveResult){
							//console.log(saveResult);
							if (saveResult.state === "SUCCESS"){
								//happy logic here
								$A.get("e.force:showToast").setParams({
									"message": "Einstein is processing your dataset"
								}).fire();
								component.find("frd").reloadRecord();
								$A.get("e.ltng:sendMessage").setParams({
									"message" : component.get("v.recordId"),
									"channel" : "datasetCreation"
								}).fire();
								$A.get("e.force:refreshView").fire();
							} else if (saveResult.state === "INCOMPLETE") {
								console.log("User is offline, device doesn't support drafts.");
							} else if (saveResult.state === "ERROR"){
								component.find("leh").passErrors(saveResult.error);
							}
						})
					);
				}
			}), $A.getCallback(function(){}));
	},


})