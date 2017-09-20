public class Vision {

public static final String VISION_API = 'https://api.einstein.ai/v1/vision';

public static final String LANGUAGE_API = 'https://api.einstein.ai/v2/language';

public static final String PREDICT = VISION_API + '/predict';
public static final String DATASET = VISION_API + '/datasets';
public static final String TRAIN = VISION_API + '/train';
public static final String RETRAIN_VISION = 'https://api.einstein.ai/v2/vision/retrain';

public static final String MODELS = VISION_API + '/models';

public static final String DATASET_LANG = LANGUAGE_API + '/datasets';
public static final String TRAIN_LANG = LANGUAGE_API + '/train';
public static final String RETRAIN_LANG = LANGUAGE_API + '/retrain';

public static final String MODELS_LANG = LANGUAGE_API + '/models';

public static final String USAGE = 'https://api.einstein.ai/v2/apiusage';

@AuraEnabled
public static string scriptHelper (string labelSFDCId){
  label__c label = [select id, name, Einstein_Label_ID__c, Model__r.EinsteinID__c from label__c where id =: labelSFDCId];
  string output = einsteinUtilities.getAccessToken() + ' ' + label.Einstein_Label_ID__c + ' ' + label.Model__r.EinsteinID__c;
  return output;
}

@AuraEnabled
public static string train(id modelId, integer epochs, boolean retrain){
  return trainWithToken(modelId, epochs, retrain, null);
}

public static string trainWithToken(id modelId, integer epochs, boolean retrain, string token){

  map<string, string> params = new map<string, string>();
  if (epochs != null){
    params.put('epochs', EncodingUtil.urlEncode(string.valueOf(epochs), 'UTF-8'));
  }

  visionModel__c vm = new VisionModel__c();
  Language_Model__c lm = new Language_Model__c();
  httpRequest req = new httpRequest();

  if (modelId.getSObjectType().getDescribe().getName()=='VisionModel__c'){
    vm = [select Name, EinsteinID__c, Einstein_Trained_Model_Id__c from visionModel__c where id=:modelId];
    if (!retrain){
      params.put('name', EncodingUtil.urlEncode(vm.Name, 'UTF-8'));
      params.put('datasetId', EncodingUtil.urlEncode(vm.EinsteinID__c, 'UTF-8'));
      req = einsteinUtilities.standardPost(null, params, TRAIN);
    } else {
      params.put('modelId', EncodingUtil.urlEncode(vm.Einstein_Trained_Model_Id__c, 'UTF-8'));
      req = einsteinUtilities.standardPost(null, params, RETRAIN_VISION);
    }
  } else if (modelId.getSObjectType().getDescribe().getName()=='Language_Model__c'){
    lm = [select Name, Einstein_Dataset_Id__c, Einstein_Model_Id__c from Language_Model__c where id=:modelId];
    if (!retrain){
      params.put('name', EncodingUtil.urlEncode(lm.Name, 'UTF-8'));
      params.put('datasetId', EncodingUtil.urlEncode(lm.Einstein_Dataset_Id__c, 'UTF-8'));
      req = einsteinUtilities.standardPost(null, params, TRAIN_LANG);
    } else {
      params.put('trainParams', '{"withFeedback" : true}');
      params.put('modelId', EncodingUtil.urlEncode(lm.Einstein_Model_Id__c, 'UTF-8'));
      req = einsteinUtilities.standardPost(null, params, RETRAIN_LANG);
    }
  }

  system.debug(params);

  system.debug(req);
  system.debug(req.getHeader('Authorization'));
  system.debug(req.getHeader('Content-Type'));
  system.debug('length ' +  req.getHeader('Content-Length'));
  system.debug(req.getBody());

  Http http = new Http();
  HTTPResponse res = http.send(req);
  system.debug(res.getStatus());
  if (res.getStatusCode()==400){
    throw new AuraHandledException(res.getBody());
  }
  system.debug(res.getStatusCode());

  string result = ParseStrings(res, 'modelId');
  if (!retrain){
    if (modelId.getSObjectType().getDescribe().getName()=='VisionModel__c'){
      vm.Einstein_Trained_Model_Id__c = result;
      update vm;
    } else if (modelId.getSObjectType().getDescribe().getName()=='Language_Model__c'){
      lm.Einstein_Model_Id__c = result;
      update lm;
    }
  }
  return result;

}

@AuraEnabled
public static string getAllModels(id recordId){
  httpRequest req = new httpRequest();
  if (recordId.getSObjectType().getDescribe().getName()=='VisionModel__c'){
    visionModel__c vm = [select EinsteinID__c from visionModel__c where id=:recordId];
    req = einsteinUtilities.simpleRequest(null, DATASET + '/' + vm.EinsteinID__c + '/models', 'GET');
  } else if (recordId.getSObjectType().getDescribe().getName()=='Language_Model__c'){
    Language_Model__c lm = [select Einstein_Dataset_Id__c from Language_Model__c where id=:recordId];
    req = einsteinUtilities.simpleRequest(null, DATASET_LANG + '/' + lm.Einstein_Dataset_Id__c + '/models', 'GET');
  }
  return einsteinUtilities.requestResponse(req);
}

@AuraEnabled
public static string getLearningCurves(string modelId){
  visionModel__c vm = [select EinsteinID__c, Einstein_Trained_Model_Id__c from visionModel__c where id=:modelId];
  string output;
  httpRequest req = einsteinUtilities.simpleRequest(null, MODELS + '/' + vm.Einstein_Trained_Model_Id__c + '/lc', 'GET');
  return einsteinUtilities.requestResponse(req);
}

@AuraEnabled
public static string getAPIusage(){
  //USAGE
  httpRequest req = einsteinUtilities.simpleRequest(null, USAGE, 'GET');
  return einsteinUtilities.requestResponse(req);
}

@AuraEnabled
public static string getModelDetails(id recordId){

  httpRequest req = new httpRequest();
  if (recordId.getSObjectType().getDescribe().getName()=='VisionModel__c'){
    visionModel__c vm = [select EinsteinID__c from visionModel__c where id=:recordId];
    req = einsteinUtilities.simpleRequest(null, DATASET + '/' + vm.EinsteinID__c, 'GET');
  } else if (recordId.getSObjectType().getDescribe().getName()=='Language_Model__c'){
    Language_Model__c lm = [select Einstein_Dataset_Id__c, Einstein_Model_Id__c  from Language_Model__c where id=:recordId];
    req = einsteinUtilities.simpleRequest(null, DATASET_LANG + '/' + lm.Einstein_Dataset_Id__c, 'GET');
  }
  return einsteinUtilities.requestResponse(req);
}


@AuraEnabled
public static string getModelMetrics(id recordId){
  httpRequest req = new httpRequest();
  if (recordId.getSObjectType().getDescribe().getName()=='VisionModel__c'){
    visionModel__c vm = [select EinsteinID__c, Einstein_Trained_Model_Id__c from visionModel__c where id=:recordId];
    req = einsteinUtilities.simpleRequest(null, MODELS + '/' + vm.Einstein_Trained_Model_Id__c, 'GET');
  } else if (recordId.getSObjectType().getDescribe().getName()=='Language_Model__c'){
    Language_Model__c lm = [select Einstein_Dataset_Id__c, Einstein_Model_Id__c  from Language_Model__c where id=:recordId];
    req = einsteinUtilities.simpleRequest(null, MODELS_LANG + '/' + lm.Einstein_Model_Id__c, 'GET');
  }

  return einsteinUtilities.requestResponse(req);
}


@future(Callout=True)
public static void createLabelFuture (id LabelId, string token){
  label__c l = [select Id, Name, Einstein_Label_ID__c, Model__r.EinsteinID__c from label__c where Id =: LabelId];
  l.Einstein_Label_ID__c = createLabel(l.Model__r.EinsteinID__c, l.Name, token);
  update l;
}

//required: modelId, labelName.  Creates label on that model and returns the labelId
public static string createLabel (string modelId, string labelName, String access_token){
  map<string, string> params = new map<string, string>();
  params.put('name', EncodingUtil.urlEncode(labelName, 'UTF-8') );

  httpRequest req = einsteinUtilities.standardPost(null, params, DATASET + '/' + modelId + '/labels');
  Http http = new Http();

  try{
    HTTPResponse res = http.send(req);
    return ParseStrings(res, 'id');
  } catch(System.CalloutException e) {
    System.debug('ERROR:' + e);
    return null;
  }
}

@future(Callout=True)
public static void deleteModel (string modelId, string access_token){
  httpRequest req = einsteinUtilities.simpleRequest(access_token, DATASET + '/' + modelId, 'DELETE');
  Http http = new Http();
  HTTPResponse res = http.send(req);
}

@future(Callout=True)
public static void createModelFuture (id ModelId, string token){
  visionModel__c vm = [select Id, Name, EinsteinID__c from visionModel__c where Id =: modelId];
  //you already got an ID?  I'm not going to overwrite it.  This supports the "standard" models
  if (vm.EinsteinID__c != null){ return;}

  vm.EinsteinID__c = createModel(vm.Name, token);
  update vm;
}

//optional access token, required model name.  Creates model on Einstein and returns the Id.
public static string createModel (string modelName, String access_token){
  map<string, string> params = new map<string, string>();

  params.put('name', EncodingUtil.urlEncode(modelName, 'UTF-8') );


  httpRequest req = einsteinUtilities.standardPost(null, params, DATASET);
  Http http = new Http();
  try{
    HTTPResponse res = http.send(req);
    return ParseStrings(res, 'id');
  } catch(System.CalloutException e) {
    System.debug('ERROR:' + e);
    return null;
  }
}



@future(Callout=true)
public static void predictChatter (id feedPostId){
  system.debug('doing chatter prediction future method');
  //get feeditem
  feeditem fi = [select Id, type, HasLink, LinkUrl, ParentId, RelatedRecordId from feeditem where id=:feedPostId];

  feedComment fc = new feedComment();
  fc.CommentType = 'TextComment';
  fc.FeedItemId = fi.id;
  EinsteinVision__c EV = EinsteinVision__c.getInstance();
  fc.createdById = EV.LocalEinsteinUser__c;

  visionModel__c vm = [select Id, Name, Einstein_Trained_Model_Id__c, Cutoff_Percentage__c, Show_alternative_classifications__c from visionModel__c where id =: fi.ParentId];
  //url link
  list<EinsteinUtilities.Prediction> predictions = new list<EinsteinUtilities.Prediction>();
  if (fi.HasLink){
    system.debug('its a link');

    predictions = predictUrl(fi.LinkUrl, einsteinUtilities.getAccessToken(), vm.Einstein_Trained_Model_Id__c);
  } else if (fi.type == 'ContentPost'){
    system.debug(' its a content post');

    contentVersion CV = [select Id, VersionData from contentVersion where Id =: fi.RelatedRecordId];
    predictions = predictBlob(CV.VersionData, einsteinUtilities.getAccessToken(), vm.Einstein_Trained_Model_Id__c);
  } else {
    system.debug('it is neither a link nor a content post.  type == ' + fi.type);
    fc.CommentBody = 'The post doesn\'t have an attachment (ContentPost) or contain an image link.  Its type is "fi.type"';
  }
  system.debug(predictions);

  //make the comment about our prediction

  fc.CommentBody = buildChatterResponse(Predictions, vm.Cutoff_Percentage__c, vm.Show_alternative_classifications__c);

  insert fc;

}

public static string buildChatterResponse (list<EinsteinUtilities.prediction> Predictions, decimal cutoff, boolean showAlternatives){
  string comment = '';

  if (predictions.size()==0){
    return 'I don\'t have an answer for that';
  }
  if (cutoff!=null && predictions[0].probability < cutoff/100){
    return 'None of my predictions meet your threshold for confidence (' + cutoff +'%)';
  }

  comment = 'Best guess:' + predictions[0].label + ' (' + math.roundToLong(predictions[0].probability*100) + ')%.';

  if (predictions.size()>1 && showAlternatives){

    string extraChoices = '';
    for (integer k=1; k<predictions.size(); k++){
      if (cutoff == null || predictions[k].probability > cutoff/100){
        extraChoices=extraChoices + ' \r\n ';
        extraChoices = extraChoices + predictions[k].label + ' (' + math.roundToLong(predictions[k].probability*100) + ')%';
      }
    }
    if (extraChoices.length()>0){
      comment = comment + ' Other possibilities: \r\n ';
      comment = comment + extraChoices;
    }
  }

  return comment;
}


public static List<EinsteinUtilities.Prediction> predictUrl(String url, String access_token, String model) {
    return predictInternal(url, access_token, model, false);
}

public static List<EinsteinUtilities.Prediction> predictBase64(String base64String, String access_token, String model) {
    return predictInternal(base64String, access_token, model, true);
}

public static List<EinsteinUtilities.Prediction> predictBlob(blob fileBlob, String access_token, String model) {
    return predictInternal(EncodingUtil.base64Encode(fileBlob), access_token, model, true);
}

//replacement for the original provided by the sample docs, but shares code with other methods
public static List<EinsteinUtilities.Prediction> predictInternal(String sample, String access_token, String model, boolean isBase64) {
  List<EinsteinUtilities.Prediction> predictions = new List<EinsteinUtilities.Prediction>();

  map<string, string> params = new map<string, string>();
  params.put('modelId', EncodingUtil.urlEncode(model, 'UTF-8'));

  if(isBase64) {
    params.put('sampleBase64Content', sample);
  } else {
    params.put('sampleLocation', sample);
  }

  httpRequest req = einsteinUtilities.standardPost(access_token, params, PREDICT);
  return einsteinUtilities.sendReqThenParsePredictions(req);

}


public static string ParseStrings (HTTPResponse res, string field){
  string result;
  system.debug(res.getBody());
  JSONParser parser = JSON.createParser(res.getBody());
  while (parser.nextToken() != null) {
          if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
              (parser.getText() == field)) {
                // Get the value.
                parser.nextToken();
                // Compute the grand total price for all invoices.
                return(parser.getText());
          }
      }
  return null;
}





}