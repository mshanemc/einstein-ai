public with sharing class InvocableLanguageFeedback {

	@InvocableMethod(label='Correct Einstein with Feedback')
	public static void AnalyzeLanguage(list<LanguageFeedback> LFs) {
		list<string> singleBatch = new list<string>();
		list<list<string>> Batches = new list<list<string>>();

		Integer Batchsize = Limits.GetLimitCallouts()-1; //because we'll use a call to get a token for each batch

		//get the actual text
		list<LanguageFeedback> deduped = dedupeLFs(LFs);

		for (LanguageFeedback LF:deduped){
			//batch is full, put it in the batch list, blank it for new adds
			if (singleBatch.size()==Batchsize){
				Batches.add(singleBatch);
				singleBatch = new list<string>();
			}
			singleBatch.add(JSON.serialize(LF));
		}

		Batches.add(singleBatch);
		for (list<string> batch:batches){
			giveFeedback(batch);
		}
	}

	@future(callout=true)
	public static void giveFeedback(list<string> input){
		string token = vision.getAccessToken();
		list<LanguageFeedback> LFs = new list<LanguageFeedback>();

		for (string s:input){
			LanguageFeedback LF = (LanguageFeedback)JSON.deserialize(s, LanguageFeedback.class);
			EinsteinLanguage.languageFeedback(LF.Text, LF.Label, LF.ModelId, token);
		}
	}

	public class LanguageFeedback {
		@InvocableVariable (required=true label='Model Id' description='Einstein Model Id, not an SFDC RecordId')
		public string ModelId;

		@InvocableVariable (required=true label='Text' description='What did Einstein classify incorrectly? Use a formula field to grab the actual text')
		public string Text;

		@InvocableVariable (required=true label='Correct Label' description='What classification should it have been?  This should be the name of a label for that model')
		public string Label;
	}

	public static list<LanguageFeedback> dedupeLFs(list<LanguageFeedback> input){
		set<LanguageFeedback> temp = new set<LanguageFeedback>(input);
		return new list<LanguageFeedback>(temp);
	}

}