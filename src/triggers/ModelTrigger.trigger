//as data is created on force, create or delete appropriate models on the Einstein side
trigger ModelTrigger on VisionModel__c (after insert, after delete) {
	if (Trigger.isAfter) {	
		if (Trigger.isInsert){
			//string token = Vision.getAccessToken();
			for (VisionModel__c vm : trigger.new){
				Vision.createModelFuture(vm.Id, null);
			}				
		} else if (Trigger.isDelete){
			//string token = Vision.getAccessToken();
			for (VisionModel__c vm : trigger.old){				
				Vision.deleteModel(vm.EinsteinID__c, null);
			}
		}   
	} 
}