({
	doInit : function(component, event, helper) {
		//	public static string getFileOptions(id recordId){
		let action = component.get("c.getFileOptions");
		action.setParams({
			"recordId" : component.get("v.recordId")
		})
		let prom = helper.executeActionJSON(component, action)
			.then($A.getCallback(function (result){
				console.log(result);
				component.set("v.files", result);
			}));
	},

	previewFile : function(component, event, helper) {
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
				component.set("v.fields.Einstein_Dataset_Id__c", result.id);
				component.find("frd").saveRecord(
					$A.getCallback(function(saveResult){
						//console.log(saveResult);
						if (saveResult.state === "SUCCESS"){
							//happy logic here
							$A.get("e.force:showToast").setParams({
								"message": result.statusMsg
							}).fire();
							component.find("frd").reloadRecord();
						} else if (saveResult.state === "INCOMPLETE") {
							console.log("User is offline, device doesn't support drafts.");
						} else if (saveResult.state === "ERROR"){
							component.find("leh").passErrors(saveResult.error);
						}
					})
				);

			}));
	},


})