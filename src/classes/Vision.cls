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

public static final String AUTH = 'https://api.einstein.ai/v1/oauth2/token';
public static final String USAGE = 'https://api.einstein.ai/v2/apiusage';

@AuraEnabled
public static string scriptHelper (string labelSFDCId){
  label__c label = [select id, name, Einstein_Label_ID__c, Model__r.EinsteinID__c from label__c where id =: labelSFDCId];
  string output = getAccessToken() + ' ' + label.Einstein_Label_ID__c + ' ' + label.Model__r.EinsteinID__c;
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
      req = Vision.standardRequest(null, params, TRAIN);
    } else {
      params.put('modelId', EncodingUtil.urlEncode(vm.Einstein_Trained_Model_Id__c, 'UTF-8'));
      req = Vision.standardRequest(null, params, RETRAIN_VISION);
    }
  } else if (modelId.getSObjectType().getDescribe().getName()=='Language_Model__c'){
    lm = [select Name, Einstein_Dataset_Id__c, Einstein_Model_Id__c from Language_Model__c where id=:modelId];
    if (!retrain){
      params.put('name', EncodingUtil.urlEncode(lm.Name, 'UTF-8'));
      params.put('datasetId', EncodingUtil.urlEncode(lm.Einstein_Dataset_Id__c, 'UTF-8'));
      req = Vision.standardRequest(null, params, TRAIN_LANG);
    } else {
      params.put('trainParams', '{"withFeedback" : true}');
      params.put('modelId', EncodingUtil.urlEncode(lm.Einstein_Model_Id__c, 'UTF-8'));
      req = Vision.standardRequest(null, params, RETRAIN_LANG);
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
    req = standard(null, DATASET + '/' + vm.EinsteinID__c + '/models', 'GET');
  } else if (recordId.getSObjectType().getDescribe().getName()=='Language_Model__c'){
    Language_Model__c lm = [select Einstein_Dataset_Id__c from Language_Model__c where id=:recordId];
    req = vision.standard(null, DATASET_LANG + '/' + lm.Einstein_Dataset_Id__c + '/models', 'GET');
  }
  return requestResponse(req);
}

@AuraEnabled
public static string getLearningCurves(string modelId){
  visionModel__c vm = [select EinsteinID__c, Einstein_Trained_Model_Id__c from visionModel__c where id=:modelId];
  string output;
  httpRequest req = standard(null, MODELS + '/' + vm.Einstein_Trained_Model_Id__c + '/lc', 'GET');
  return requestResponse(req);
}

@AuraEnabled
public static string getAPIusage(){
  //USAGE
  httpRequest req = standard(null, USAGE, 'GET');
  return requestResponse(req);
}

@AuraEnabled
public static string getModelDetails(id recordId){

  httpRequest req = new httpRequest();
  if (recordId.getSObjectType().getDescribe().getName()=='VisionModel__c'){
    visionModel__c vm = [select EinsteinID__c from visionModel__c where id=:recordId];
    req = standard(null, DATASET + '/' + vm.EinsteinID__c, 'GET');
  } else if (recordId.getSObjectType().getDescribe().getName()=='Language_Model__c'){
    Language_Model__c lm = [select Einstein_Dataset_Id__c, Einstein_Model_Id__c  from Language_Model__c where id=:recordId];
    req = standard(null, DATASET_LANG + '/' + lm.Einstein_Dataset_Id__c, 'GET');
  }
  return requestResponse(req);
}

public static string requestResponse(httpRequest req){
  Http http = new Http();
  HTTPResponse res = http.send(req);
  system.debug(res.getBody());
  return res.getBody();
}

@AuraEnabled
public static string getModelMetrics(id recordId){
  httpRequest req = new httpRequest();
  if (recordId.getSObjectType().getDescribe().getName()=='VisionModel__c'){
    visionModel__c vm = [select EinsteinID__c, Einstein_Trained_Model_Id__c from visionModel__c where id=:recordId];
    req = standard(null, MODELS + '/' + vm.Einstein_Trained_Model_Id__c, 'GET');
  } else if (recordId.getSObjectType().getDescribe().getName()=='Language_Model__c'){
    Language_Model__c lm = [select Einstein_Dataset_Id__c, Einstein_Model_Id__c  from Language_Model__c where id=:recordId];
    req = standard(null, MODELS_LANG + '/' + lm.Einstein_Model_Id__c, 'GET');
  }

  return requestResponse(req);
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


  httpRequest req = standardRequest(null, params, DATASET + '/' + modelId + '/labels');
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
  httpRequest req = standard(access_token, DATASET + '/' + modelId, 'DELETE');
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


  httpRequest req = standardRequest(null, params, DATASET);
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
  list<Prediction> predictions = new list<Prediction>();
  if (fi.HasLink){
    system.debug('its a link');

    predictions = predictUrl(fi.LinkUrl, getAccessToken(), vm.Einstein_Trained_Model_Id__c);
  } else if (fi.type == 'ContentPost'){
    system.debug(' its a content post');

    contentVersion CV = [select Id, VersionData from contentVersion where Id =: fi.RelatedRecordId];
    predictions = predictBlob(CV.VersionData, getAccessToken(), vm.Einstein_Trained_Model_Id__c);
  } else {
    system.debug('it is neither a link nor a content post.  type == ' + fi.type);
    fc.CommentBody = 'The post doesn\'t have an attachment (ContentPost) or contain an image link.  Its type is "fi.type"';
  }
  system.debug(predictions);

  //make the comment about our prediction

  fc.CommentBody = buildChatterResponse(Predictions, vm.Cutoff_Percentage__c, vm.Show_alternative_classifications__c);

  insert fc;

}

public static string buildChatterResponse (list<prediction> Predictions, decimal cutoff, boolean showAlternatives){
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


public static List<Prediction> predictUrl(String url, String access_token, String model) {
    return predictInternal(url, access_token, model, false);
}

public static List<Prediction> predictBase64(String base64String, String access_token, String model) {
    return predictInternal(base64String, access_token, model, true);
}

public static List<Prediction> predictBlob(blob fileBlob, String access_token, String model) {
    return predictInternal(EncodingUtil.base64Encode(fileBlob), access_token, model, true);
}

public static blob makeBody(map<string, string> params){
  string form64 = '';
  form64 += HttpFormBuilder.WriteBoundary();
  integer mapCounter = 0;
  //iterate the params and do the boundary thing
  for (string key : params.keySet()){
    mapCounter = mapCounter + 1;
    string item = HttpFormBuilder.WriteBodyParameter(key, params.get(key));
    system.debug(item);

    form64 += item;
    //form64 += HttpFormBuilder.WriteBodyParameter(key, EncodingUtil.urlEncode(params.get(key), 'UTF-8'));
    if (mapCounter==params.size()){
       //last one
        form64 += HttpFormBuilder.WriteBoundary(null); //suggestion from product team
        //form64 += HttpFormBuilder.WriteBoundary(HttpFormBuilder.EndingType.CrLf);
      } else { //not the last one
        form64 += HttpFormBuilder.WriteBoundary();
      }
  }

  blob formBlob = EncodingUtil.base64Decode(form64);
  return formBlob;

}

//replacement for the original provided by the sample docs, but shares code with other methods
public static List<Prediction> predictInternal(String sample, String access_token, String model, boolean isBase64) {
  List<Prediction> predictions = new List<Prediction>();

  map<string, string> params = new map<string, string>();
  params.put('modelId', EncodingUtil.urlEncode(model, 'UTF-8'));

  if(isBase64) {
    params.put('sampleBase64Content', sample);
  } else {
    params.put('sampleLocation', sample);
  }

  httpRequest req = standardRequest(access_token, params, PREDICT);
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
                            Prediction probability = (Prediction)parser.readValueAs(Vision.Prediction.class);
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

public static httpRequest standardRequest(string access_token, map<string, string> params, string endpoint){
  if (access_token == null){
    access_token = getAccessToken();
  }

  blob formBlob = makeBody(params);

  HttpRequest output = new HttpRequest();
  output.setHeader('Content-Length', string.valueOf(formBlob.size()));
  output.setHeader('Cache-Control', 'no-cache');
  output.setMethod('POST');
  output.setTimeout(120000);
  output.setHeader('Content-Type', HttpFormBuilder.GetContentType());
  output.setHeader('Authorization','Bearer ' + access_token);
  output.setBodyAsBlob(formBlob);
  output.setEndpoint(endpoint);

  return output;
}


public class Prediction {
    public String label {get;set;}
    public Double probability {get;set;}
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


public static httpRequest standard(string access_token, string endpoint, string method){
  if (access_token == null){
    access_token = getAccessToken();
  }

  HttpRequest output = new HttpRequest();
  output.setMethod(method);
  output.setTimeout(120000);
  output.setHeader('Authorization','Bearer ' + access_token);
  output.setEndpoint(endpoint);

  return output;
}

public class EinsteinAuthException extends Exception{}

@AuraEnabled
public static String getAccessToken() {

    EinsteinVision__c EV = EinsteinVision__c.getInstance();
    JWT jwt = new JWT('RS256');

    if (EV.CertName__c == null && EV.CertFile__c!=null){
      try{
        ContentVersion base64Content = [SELECT Title, VersionData FROM ContentVersion where Title=:EV.CertFile__c ORDER BY Title LIMIT 1];
        String keyContents = base64Content.VersionData.tostring();
        keyContents = keyContents.replace('-----BEGIN RSA PRIVATE KEY-----', '');
        keyContents = keyContents.replace('-----END RSA PRIVATE KEY-----', '');
        keyContents = keyContents.replace('\n', '');
        jwt.pkcs8 = keyContents;
      } catch (exception e){
        throw new AuraHandledException('The certificate file was not found.  Check that it is installed, named correctly in the custom settings, and visible to all users who need to use it');
      }

    } else if (EV.CertName__c != null && EV.CertFile__c==null){
      jwt.cert = EV.CertName__c;
    } else {
      throw new EinsteinAuthException('Your custom settings are not set up properly.  Either CertFile or CertName should be populated');
    }

    jwt.iss = EV.certificateIssuer__c;
    jwt.sub = EV.EinsteinUsername__c;
    jwt.aud = AUTH;
    jwt.validFor = integer.valueOf(EV.TokenExpirationTime__c);
    String access_token = JWTBearerFlow.getAccessToken(AUTH, jwt);

    system.debug(access_token);
    return access_token;
}



}
//original, provided by docs
/*
private static List<Prediction> predictInternal2(String sample, String access_token, String model, boolean isBase64) {
    string contentType = HttpFormBuilder.GetContentType();
    //  Compose the form
    string form64 = '';

    form64 += HttpFormBuilder.WriteBoundary();
    form64 += HttpFormBuilder.WriteBodyParameter('modelId', EncodingUtil.urlEncode(model, 'UTF-8'));
    form64 += HttpFormBuilder.WriteBoundary();
    if(isBase64) {
     form64 += HttpFormBuilder.WriteBodyParameter('sampleBase64Content', sample);
    } else {
     form64 += HttpFormBuilder.WriteBodyParameter('sampleLocation', sample);
    }
    form64 += HttpFormBuilder.WriteBoundary(HttpFormBuilder.EndingType.CrLf);

    blob formBlob = EncodingUtil.base64Decode(form64);
    string contentLength = string.valueOf(formBlob.size());
    //  Compose the http request
    HttpRequest httpRequest = new HttpRequest();

    httpRequest.setBodyAsBlob(formBlob);
    httpRequest.setHeader('Connection', 'keep-alive');
    httpRequest.setHeader('Content-Length', contentLength);
    httpRequest.setHeader('Content-Type', contentType);
    httpRequest.setMethod('POST');
    httpRequest.setTimeout(120000);
    httpRequest.setHeader('Authorization','Bearer ' + access_token);
    httpRequest.setEndpoint(PREDICT);

    Http http = new Http();
    List<Prediction> predictions = new List<Prediction>();
    try {
          HTTPResponse res = http.send(httpRequest);

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
                                    Prediction probability = (Prediction)parser.readValueAs(Vision.Prediction.class);
                                    predictions.add(probability);
                                }
                            }
                        }
                  break;
                  }
              }
          }

     } catch(System.CalloutException e) {
            System.debug('ERROR:' + e);
     }
     return(predictions);
}
*/