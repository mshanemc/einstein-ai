trigger LanguageModelTrigger on Language_Model__c (after delete) {
	if (Trigger.isAfter) {
		if (Trigger.isDelete){
			//string token = Vision.getAccessToken();
			for (Language_Model__c lm : trigger.old){
				EinsteinLanguage.deleteModel(lm.Einstein_Dataset_Id__c, null);
			}
		}
	}
}