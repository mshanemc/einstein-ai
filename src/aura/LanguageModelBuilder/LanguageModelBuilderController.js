({
	doInit : function(component, event, helper) {
		let action = component.get("c.getObjectOptions");
		let prom = helper.executeActionJSON(component, action)
			.then($A.getCallback(function (result){
				console.log(result);
				component.set("v.objects", result);
				//TODO: lodash to alphabetize that crap!
			}));
	},

	getFields : function(component, event, helper) {
		let source = component.get("c.getObjectFields");
		source.setParams({
			"objectName" : component.get("v.selectedObject"),
			"sourceOrLabel" : "Source"
		});
		let prom = helper.executeActionJSON(component, source)
			.then($A.getCallback(function (result){
				console.log(result);
				component.set("v.sourceFields", result);
				//TODO: lodash to alphabetize!
			}));

		let classify = component.get("c.getObjectFields");
		classify.setParams({
			"objectName" : component.get("v.selectedObject"),
			"sourceOrLabel" : "Label"
		});
		let prom2 = helper.executeActionJSON(component, classify)
			.then($A.getCallback(function (result){
				console.log(result);
				component.set("v.classificationFields", result);
				//TODO: lodash to alphabetize!
			}));
	},

	getFile : function(component, event, helper) {
		let saveFile = component.get("c.saveFileToFiles");
		saveFile.setParams({
			"SFDCmodelId" : component.get("v.recordId"),
			"obj" : component.get("v.selectedObject"),
			"src" : component.get("v.selectedSourceField"),
			"classify" : component.get("v.selectedclassificationField"),
		});
		let prom = helper.executeActionJSON(component, saveFile)
			.then($A.getCallback(function (result){
				console.log(result);
				$A.get("e.force:showToast").setParams({
					"message": "Your file is in the Chatter feed",
					"title" : "Success!",
					"type" : "success"
				}).fire();
				$A.get("e.force:refreshView").fire();
			}));
	},

	makeModel : function(component, event, helper) {
		let saveFile = component.get("c.createDataset");
		saveFile.setParams({
			"SFDCmodelId" : component.get("v.recordId"),
			"obj" : component.get("v.selectedObject"),
			"src" : component.get("v.selectedSourceField"),
			"classify" : component.get("v.selectedclassificationField"),
		});
		let prom = helper.executeActionJSON(component, saveFile)
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
									"message": "Dataset created.  Next, Train a model from this dataset."
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
				} else if (result.message) {
					component.find("leh").passErrors(	[{"message" : result.message }] );
				}
			}));
	},



})