({
	doInit : function(component, event, helper) {
		//public static string getModelDetails(string modelId){
		//console.log("record Id is " + component.get("v.recordId"));
		
		var that = this;
		
		var action = component.get("c.getModelDetails")
		action.setParams({ "modelId" : component.get("v.recordId")});

		var action2 = component.get("c.getModelMetrics")
		action2.setParams({ "modelId" : component.get("v.recordId")});


		action.setCallback(this, function (a){
			//console.log(a);
			//console.log(JSON.parse(a.getReturnValue()));
			
			var data = 	JSON.parse(a.getReturnValue())
			console.log(data);		
			//will get overwritten if we get back anything useful
			component.set("v.data", data);

			action2.setCallback(that, function (b){
				if (b.getReturnValue() != '{"message":"Unable to parse job ID null"}'){

					try {
						var metrics = JSON.parse(b.getReturnValue());
						console.log(metrics);
						//component.set("v.metrics", metrics);

						for (var i=0; i<data.labelSummary.labels.length; i++){						
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
				}	
			});
			$A.enqueueAction(action2);		
		});
		
		$A.enqueueAction(action);
		
		/*
		action2.setCallback(this, function (a){
			//console.log(a);
			var metrics = JSON.parse(a.getReturnValue());
			console.log(metrics);
			//component.set("v.metrics", metrics);
			var data = component.get("v.data");

			for (var i=0; i<data.labelSummary.labels.length; i++){
				console.log("iteration " + i);
				//set f1
				data.labelSummary.labels[i].f1 = metrics.metricsData.f1[i];
				data.labelSummary.labels[i].confusionMatrix = metrics.metricsData.confusionMatrix[i];			
			}
			data.testAccuracy = metrics.testAccuracy;
			data.trainingLoss = metrics.trainingLoss;
			data.trainingAccuracy = metrics.trainingAccuracy;
			console.log(data);
			component.set("v.data", data);		
		});*/

		var action4 = component.get("c.getAccessToken")
		action4.setCallback(this, function (a){
			//console.log(a);
			console.log(a.getReturnValue());
			component.set("v.token", a.getReturnValue());		
		});
		$A.enqueueAction(action4);


		
	}
})