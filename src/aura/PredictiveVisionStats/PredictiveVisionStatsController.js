({
	doInit : function(component, event, helper) {

		let action = component.get("c.getModelDetails");
		action.setParams({ "recordId" : component.get("v.recordId")});

		helper.executeActionJSON(component, action)
			.then($A.getCallback(function (data){
				console.log(data);
				component.set("v.data", data);
				component.set("v.done", true);

				if (data.available){
					let action2 = component.get("c.getModelMetrics");
					action2.setParams({ "recordId" : component.get("v.recordId")});
					return helper.executeActionJSON(component, action2);
				}
			}))
			.then($A.getCallback(function (metrics){
				let data = component.get("v.data");
				try {
					for (let i=0; i<data.labelSummary.labels.length; i++){
						data.labelSummary.labels[i].f1 = metrics.metricsData.f1[i];
						data.labelSummary.labels[i].confusionMatrix = metrics.metricsData.confusionMatrix[i];
					}
					data.testAccuracy = metrics.metricsData.testAccuracy;
					data.trainingLoss = metrics.metricsData.trainingLoss;
					data.trainingAccuracy = metrics.metricsData.trainingAccuracy;
					//console.log(data);
					component.set("v.data", data);
				} catch (err){
					console.log("no data available for this model");
				}
			}), $A.getCallback(function(){}));

	}
})