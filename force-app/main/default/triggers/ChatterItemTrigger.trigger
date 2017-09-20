trigger ChatterItemTrigger on feeditem (after insert) {

	system.debug('chatter item trigger');

	for (feeditem fi:trigger.new){
		
		if (fi.ParentId.getSObjectType() == VisionModel__c.SObjectType){
			Vision.predictChatter(fi.Id);
		} else if (fi.ParentId.getSObjectType() == Label__c.SObjectType){
			//send example to that label
			//Vision.pChatter(fi.Id);
		}
	}

}