public with sharing class EinsteinLanguage {

	public static final String LANGUAGE_API = 'https://api.einstein.ai/v2/language';
	public static final String INTENT = LANGUAGE_API + '/intent';
	public static final String SENTIMENT = LANGUAGE_API + '/sentiment';
	public static final String DATASET = LANGUAGE_API + '/datasets';
	public static final String TRAIN = LANGUAGE_API + '/train';
	public static final String RETRAIN = LANGUAGE_API + '/retrain';
	public static final String MODELS = LANGUAGE_API + '/models';
	public static final String DEFAULTSENTIMENT = 'CommunitySentiment';
	public static final String AUTH = 'https://api.einstein.ai/v2/oauth2/token';

	public class LanguageException extends exception {}

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
				tempMap.put('label', dsor.getLabel());
				tempMap.put('name', dsor.getName());
				output.add(tempMap);
			}

		}
		system.debug(output);
		return JSON.serialize(output);
	}

	@AuraEnabled
	public static string getFileOptions(id recordId){
		return JSON.serialize(
			[select id, ContentDocument.Id, ContentDocument.Title, ContentDocument.LatestPublishedVersionId from ContentDocumentLink where linkedEntityId =: recordId ]
		);
	}

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
				tempMap.put('label', dfr.getLabel());
				tempMap.put('name', dfr.getName());
				tempMap.put('type', dfr.getType().name());
				output.add(tempMap);
			}
		} //end for loop of fieldmap

		system.debug(output);
		return JSON.serialize(output);
	}

	@AuraEnabled
	public static string createDatasetPart2(string SFDCmodelId, string CDID){

		ContentDistribution CD = [select id, ContentDownloadURL from ContentDistribution where Id=:CDID];
		Language_Model__c LM = [select id, name, Model_Type__c from Language_Model__c where id=:SFDCmodelId];
		system.debug(LM);
		map<string, string> params = new map<string, string>();

		params.put('path', CD.ContentDownloadURL);
		if (LM.Model_Type__c == 'Sentiment'){
			params.put('type', 'text-sentiment');
		} else if (LM.Model_Type__c == 'Intent'){
			params.put('type', 'text-intent');
		} else {
			throw new LanguageException('unsupported type : ' + LM.Model_Type__c);
		}
		params.put('name', LM.Name);
		system.debug(params);

		//https://requestb.in/1e8a66d1

		httpRequest req = Vision.standardRequest(null, params, DATASET+ '/upload');
		//httpRequest req = Vision.standardRequest(null, params, 'https://requestb.in/1e8a66d1');
		req.setHeader('Connection', 'keep-alive');
		system.debug(req);

		Http http = new Http();
  	HTTPResponse res = http.send(req);

	  System.debug(res.toString());
	  System.debug('STATUS:'+res.getStatus());
	  System.debug('STATUS_CODE:'+res.getStatusCode());

	  string output =  res.getBody();
  	system.debug(output);
  	return output;

	}

	@AuraEnabled
	public static string createCDistFromAttachedFile(id CVid){

		ContentDistribution CD = writeCD(CVid, 'EinsteinTestCDLFromFile');
		return JSON.serialize(CD);
	}

	@AuraEnabled
	public static string createDataset(string SFDCmodelId, string obj, string src, string classify){
		ContentVersion CV = new ContentVersion();
		CV.VersionData = blob.valueof(makeCSV(SFDCmodelId, obj, src, classify));
		CV.PathOnClient = 'EinsteinTrainingFile.csv';
		CV.Title = 'EinsteinTrainingFile';

		insert CV;

		return JSON.serialize(writeCD(CV.Id, CV.Title+'Distro'));
	}

	private static ContentDistribution writeCD(id contentVersionId, string name){
		ContentDistribution CD = new ContentDistribution();
		CD.ContentVersionId = contentVersionId;
		CD.Name = name;
		CD.PreferencesAllowOriginalDownload = true;
		CD.PreferencesLinkLatestVersion = true;
		CD.ExpiryDate = system.now().addMinutes(5);
		CD.PreferencesExpires = true;
		CD.PreferencesNotifyOnVisit = false;
		CD.PreferencesNotifyRndtnComplete = false;
		insert CD;

		return CD;
	}

	@AuraEnabled
	public static string saveFileToFiles(string SFDCmodelId, string obj, string src, string classify){

		ContentVersion CV = new ContentVersion();
		CV.VersionData = blob.valueof(makeCSV(SFDCmodelId, obj, src, classify));
		CV.PathOnClient = 'EinsteinTrainingFile.csv';
		CV.Title = 'EinsteinTrainingFile';

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


	private static string makeCSV (string SFDCmodelId, string obj, string src, string classify){
		string query = 'select ' +src+ ', ' +classify+ ' from ' +obj+ ' where ' + src + '!= null and ' + classify + '!= null limit 50000';

		list<sobject> data = database.query(query);

		list<string> lines = new list<string>();

		for (sobject so:data){
			string thisLine = '"' + (string)so.get(src) + '",' + (string)so.get(classify);
			lines.add(thisLine);
		}

		string csv = string.join(lines, '\n');
		system.debug(csv);
		return csv;
	}


	public static list<Vision.Prediction> Predict (string text){
		return Predict(text, null, null, null);
	}

	public static list<Vision.Prediction> Intent (string text, string modelId){
		return Predict(text, 'Intent', modelId, null);
	}

	public static list<Vision.Prediction> Sentiment (string text){
		return Predict(text, 'Sentiment', null, null);
	}

	public static list<Vision.Prediction> Sentiment (string text, string modelId){
		return Predict(text, 'Sentiment', modelId, null);
	}

	public static list<Vision.Prediction> Predict (string text, string modelType, string modelId){
		return Predict(text, modelType, modelId, null);
	}

	public static list<Vision.Prediction> Predict (string text, string modelType, string modelId, string access_token){
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

		list<Vision.Prediction> predictions = new list<Vision.Prediction>();

		map<string, string> params = new map<string, string>();

		params.put('modelId', EncodingUtil.urlEncode(modelId, 'UTF-8'));
		//params.put('document', EncodingUtil.urlEncode(text, 'UTF-8'));
		params.put('document', text);

		system.debug(params);

		httpRequest req = Vision.standardRequest(access_token, params, endpoint);
	  //httpRequest req = Vision.standardRequest(access_token, params, 'https://requestb.in/uz03lruz');



	  req.setHeader('Connection', 'keep-alive');

  	Http http = new Http();
  	HTTPResponse res = http.send(req);

	  System.debug(res.toString());
	  System.debug('STATUS:'+res.getStatus());
	  System.debug('STATUS_CODE:'+res.getStatusCode());

	  if (res.getStatusCode() == 200) {
      System.JSONParser parser = System.JSON.createParser(res.getBody());
      while (parser.nextToken() != null) {
          if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'probabilities')) {
              parser.nextToken();
                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                    while (parser.nextToken() != null) {
                        // Advance to the start object marker to
                        //  find next probability object.
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                            // Read entire probability object
                            Vision.Prediction probability = (Vision.Prediction)parser.readValueAs(Vision.Prediction.class);
                            predictions.add(probability);
                        }
                    }
                }
          break;
          }
      }
  	}

  	return predictions;
	}
}