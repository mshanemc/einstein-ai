public with sharing class InvocableEinsteinReTraining {
	@InvocableMethod(label='Train/Retrain an Einstein Model')

	public static void Retrain(list<trainRequest> LFs) {
		list<string> singleBatch = new list<string>();
		list<list<string>> Batches = new list<list<string>>();

		Integer Batchsize = Limits.GetLimitCallouts()-1; //because we'll use a call to get a token for each batch

		//get the actual text
		list<trainRequest> deduped = dedupe(LFs);

		for (trainRequest LF:deduped){
			//batch is full, put it in the batch list, blank it for new adds
			if (singleBatch.size()==Batchsize){
				Batches.add(singleBatch);
				singleBatch = new list<string>();
			}
			singleBatch.add(JSON.serialize(LF));
		}

		Batches.add(singleBatch);
		for (list<string> batch:batches){
			send(batch);
		}
	}


	@future(callout=true)
	public static void send(list<string> input){
		string token = vision.getAccessToken();

		for (string s:input){
			trainRequest LF = (trainRequest)JSON.deserialize(s, trainRequest.class);
			Vision.trainWithToken(LF.SFDCid, null, LF.retrain, token);
		}
	}

	public class trainRequest {
		@InvocableVariable (required=true label='Model Id' description='SFDC RecordId of the dataset to re/train')
		public string SFDCId;

		//@InvocableVariable (required=true label='Retrain' description='Retrain will keep the current model Id; otherwise, a new model is created')
		public boolean retrain;

	}

	public static list<trainRequest> dedupe(list<trainRequest> input){
		set<trainRequest> temp = new set<trainRequest>(input);
		return new list<trainRequest>(temp);
	}
}