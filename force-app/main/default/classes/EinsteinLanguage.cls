public with sharing class EinsteinLanguage {

	public static final String LANGUAGE_API = 'https://api.einstein.ai/v2/language';
	public static final String INTENT = LANGUAGE_API + '/intent';
	public static final String SENTIMENT = LANGUAGE_API + '/sentiment';
	public static final String DATASET = LANGUAGE_API + '/datasets';
	public static final String TRAIN = LANGUAGE_API + '/train';
	public static final String RETRAIN = LANGUAGE_API + '/retrain';
	public static final String MODELS = LANGUAGE_API + '/models';
	public static final String DEFAULTSENTIMENT = 'CommunitySentiment';
	public static final String FEEDBACK = LANGUAGE_API + '/feedback';

	public static final String AUTH = 'https://api.einstein.ai/v2/oauth2/token';

	public static final integer EXPIRY=10080; //documents become non publicly accessible after this many minutes

	public class LanguageException extends exception {}

	/*
	Queries the list of objects in the org that a dataset can be built from
	*/
	@AuraEnabled
	public static string getObjectOptions(){

		Map<String, Schema.SObjectType> objects = Schema.getGlobalDescribe();

		list<map<string, string>> output = new list<map<string, string>>();
		for (string s:objects.keySet()){
			DescribeSObjectResult dsor = objects.get(s).getDescribe();
			if (
				//if you can't update anything, you won't be able to save a prediction anywhere!
				dsor.isUpdateable() &&
				!dsor.isCustomSetting() //no custom settings
			) {
				map<string, string> tempMap = new map<string, string>();
				if (dsor.getLabel() != dsor.getName()){
					tempMap.put('label', dsor.getLabel() + ' (' + dsor.getName() + ')');
				} else {
					tempMap.put('label', dsor.getLabel());
				}
				tempMap.put('name', dsor.getName());
				output.add(tempMap);
			}

		}
		system.debug(output);
		return JSON.serialize(output);
	}

	/*
	For the given record Id, return the attachments that can be used to build a dataset
	*/
	@AuraEnabled
	public static string getFileOptions(id recordId){
		return JSON.serialize(
			[select id, ContentDocument.Id, ContentDocument.Title, ContentDocument.LatestPublishedVersionId from ContentDocumentLink where linkedEntityId =: recordId ]
		);
	}

	/*for a given object, return the fields that are sources of text (string, textarea) or labels (picklist, boolean)*/
	@AuraEnabled
	public static string getObjectFields(string objectName, string sourceOrLabel){
		list<string> temp = new list<string>();
		temp.add(objectName);

		List<Schema.DescribeSObjectResult> describe = Schema.describeSObjects(temp);

		map<string, Schema.SObjectField> fieldmap = describe[0].fields.getMap();

		list<map<string, string>> output = new list<map<string, string>>();

		for (Schema.SObjectField field:fieldmap.values()){
			DescribeFieldResult dfr = field.getDescribe();
			if (
					(sourceOrLabel=='Source'
							&& (dfr.getType().name()=='String' || dfr.getType().name()=='TextArea')
					) ||
					(sourceOrLabel=='Label'
							&& (dfr.getType().name()=='Picklist' || dfr.getType().name()=='Boolean')
					)
			){
				map<string, string> tempMap = new map<string, string>();
				if (dfr.getLabel() != dfr.getName()){
					tempMap.put('label', dfr.getLabel() + ' (' + dfr.getName() + ')' + ' [' + dfr.getType().name() + ']');
				} else {
					tempMap.put('label', dfr.getLabel() + ' [' + dfr.getType().name() + ']');
				}
				tempMap.put('name', dfr.getName());
				tempMap.put('type', dfr.getType().name());
				output.add(tempMap);
			}
		} //end for loop of fieldmap

		system.debug(output);
		return JSON.serialize(output);
	}

	//future wrapper for dataset creation method
	@future(callout=true)
	public static void createDatasetFuture(string SFDCmodelId, string CDID){
		createDatasetPart2(SFDCmodelId, CDID);
	}

	//deletes a model.  Called by a delete trigger on the model object.  Keeps your Einstein clean!
	@future(Callout=True)
	public static void deleteModel (string modelId, string access_token){
	  httpRequest req = einsteinUtilities.simpleRequest(access_token, DATASET + '/' + modelId, 'DELETE');
		// don't return anything
		einsteinUtilities.requestResponse(req);
	}

	/*
	data set creation
	 - part 1 creates the csv file
	 - part 2 puts it as an accessible url and sends that to Einstein
	*/
	@AuraEnabled
	public static string createDatasetPart2(string SFDCmodelId, string CDID){

		ContentDistribution CD = [select id, ContentDownloadURL from ContentDistribution where Id=:CDID];
		Language_Model__c LM = [select id, name, Model_Type__c from Language_Model__c where id=:SFDCmodelId];
		system.debug(LM);
		map<string, string> params = new map<string, string>();

		params.put('path', EncodingUtil.urlDecode(CD.ContentDownloadURL, 'UTF-8'));
		if (LM.Model_Type__c == 'Sentiment'){
			params.put('type', 'text-sentiment');
		} else if (LM.Model_Type__c == 'Intent'){
			params.put('type', 'text-intent');
		} else {
			throw new LanguageException('unsupported type : ' + LM.Model_Type__c);
		}
		params.put('name', LM.Name);
		system.debug(params);


		httpRequest req = einsteinUtilities.standardPost(null, params, DATASET+ '/upload');
		req.setHeader('Connection', 'keep-alive');
		system.debug(req);

		return einsteinUtilities.requestResponse(req);
	}

	@AuraEnabled
	public static string createCDistFromAttachedFile(id CVid){

		ContentDistribution CD = writeCD(CVid, 'EinsteinTestCDLFromFile');
		return JSON.serialize(CD);
	}

	@AuraEnabled
	public static string createDataset(string SFDCmodelId, string obj, string src, string classify){

		Language_Model__c lm = [select id, name from Language_Model__c where id=:SFDCmodelId];
		ContentVersion CV = new ContentVersion();
		CV.VersionData = blob.valueof(makeCSV(obj, src, classify));
		CV.PathOnClient = lm.name.replace(' ', '') + '.csv';
		CV.Title = lm.name.replace(' ', '');

		insert CV;

		return JSON.serialize(writeCD(CV.Id, CV.Title+'GeneratedDataset'));
	}

	private static ContentDistribution writeCD(id contentVersionId, string name){
		ContentDistribution CD = new ContentDistribution();
		CD.ContentVersionId = contentVersionId;
		CD.Name = 'EinsteinTemp'+ name;
		CD.PreferencesAllowOriginalDownload = true;
		CD.PreferencesLinkLatestVersion = true;
		CD.ExpiryDate = system.now().addMinutes(EXPIRY);
		CD.PreferencesExpires = true;
		CD.PreferencesNotifyOnVisit = false;
		CD.PreferencesNotifyRndtnComplete = false;
		insert CD;

		return CD;
	}

	@AuraEnabled
	public static string saveFileToFiles(string SFDCmodelId, string obj, string src, string classify){
		Language_Model__c lm = [select id, name from Language_Model__c where id=:SFDCmodelId];

		ContentVersion CV = new ContentVersion();
		CV.VersionData = blob.valueof(makeCSV(obj, src, classify));
		CV.PathOnClient = lm.name.replace(' ', '') + '.csv';
		CV.Title = lm.name.replace(' ', '');

		insert CV;

		ContentVersion CV2 = [select id, ContentDocumentId from ContentVersion where id=: CV.id];
		FeedItem fi = new FeedItem();
		fi.body = 'Here\'s your new Einstein Language model training data';
		fi.ParentId = SFDCmodelId;
		fi.RelatedRecordId = CV2.id;
		fi.Type = 'ContentPost';
		insert fi;

		return JSON.serialize(CV);

	}

	//for long text areas with newlines, get rid of them so they don't confuse the file or the learning
	public static string csvLineClean(string input){
		string output = input;
		output = output.replaceAll('\\r\\n', ' ');
		output = output.replaceAll('\\n', ' ');
		output = output.replaceAll('\"', '\'');
		return output;
	}

	public static string makeCSV (string obj, string src, string classify){
		string query = 'select ' +src+ ', ' +classify+ ' from ' +obj+ ' where ' + classify + '!= null limit 50000';

		list<sobject> data = database.query(query);

		list<string> lines = new list<string>();

		for (sobject so:data){
			system.debug(so);
			if ((string)so.get(src)!=null){ //filter for null src field here, since we can't avoid them in SOQL where
				string thisLine = '"' + csvLineClean((string)so.get(src)) + '",' + '"' + csvLineClean((string)so.get(classify)) + '"';
				lines.add(thisLine);
			}
		}

		string csv = string.join(lines, '\n');

		system.debug(csv);
		return csv;
	}

	public static string languageFeedback(string text, string label, string modelId, string token){
		map<string, string> params = new map<string, string>();

		params.put('modelId', EncodingUtil.urlEncode(modelId, 'UTF-8'));
		params.put('document', text);
		params.put('expectedLabel', EncodingUtil.urlEncode(label, 'UTF-8'));

		system.debug(params);

		httpRequest req = einsteinUtilities.standardPost(token, params, FEEDBACK);

		return einsteinUtilities.requestResponse(req);
	}

	//Primary Predict method for Language
	public static list<einsteinUtilities.Prediction> Predict (string text, string modelType, string modelId, string access_token){
		string endpoint;

		if (modelType == null || modelType.equalsIgnoreCase('Sentiment')){
			endpoint = SENTIMENT;
		} else if (modelType.equalsIgnoreCase('Intent')){
			endpoint = INTENT;
		} else {
			throw new LanguageException('Valid values for languageType are \"Sentiment\" and \"Intent\"');
		}

		//default model for sentiment
		if (modelId == null){
			if (endpoint == SENTIMENT){
				modelId = DEFAULTSENTIMENT;
			} else {
				throw new LanguageException('ModelId is required when languageType = \"Intent\"');
			}
		}

		map<string, string> params = new map<string, string>();

		params.put('modelId', EncodingUtil.urlEncode(modelId, 'UTF-8'));
		params.put('document', text);

		system.debug(params);

		httpRequest req = einsteinUtilities.standardPost(access_token, params, endpoint);
		return einsteinUtilities.sendReqThenParsePredictions(req);

	}

	//shorthand methods for Predict
	public static list<einsteinUtilities.Prediction> Predict (string text){
		return Predict(text, null, null, null);
	}

	public static list<einsteinUtilities.Prediction> Intent (string text, string modelId){
		return Predict(text, 'Intent', modelId, null);
	}

	public static list<einsteinUtilities.Prediction> Sentiment (string text){
		return Predict(text, 'Sentiment', null, null);
	}

	public static list<einsteinUtilities.Prediction> Sentiment (string text, string modelId){
		return Predict(text, 'Sentiment', modelId, null);
	}

	public static list<einsteinUtilities.Prediction> Predict (string text, string modelType, string modelId){
		return Predict(text, modelType, modelId, null);
	}


	// for a given dataset, get the labels for displaying label/example quantity
	@AuraEnabled
	public static string getLabels(id recordId){
	  Language_Model__c lm = [select Einstein_Dataset_Id__c from Language_Model__c where id=:recordId];
		httpRequest req = einsteinUtilities.simpleRequest(null, DATASET + '/' + lm.Einstein_Dataset_Id__c, 'GET');
		return einsteinUtilities.requestResponse(req);

	}

}