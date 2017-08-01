trigger ModelLabelTrigger on Label__c (after insert ) {
		//string token = Vision.getAccessToken();
		for (Label__c l : trigger.new){
			Vision.createLabelFuture(l.Id, null);
		}
	}