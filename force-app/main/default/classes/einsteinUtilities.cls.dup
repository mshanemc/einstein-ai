public with sharing class einsteinUtilities {

    public static final String AUTH = 'https://api.einstein.ai/v1/oauth2/token';



    @AuraEnabled
    public static String getAccessToken() {

        EinsteinVision__c EV = EinsteinVision__c.getInstance();
        JWT jwt = new JWT('RS256');

        if (EV.CertName__c == null && EV.CertFile__c!=null){
        //newer file-based key version
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
        //older self-signed certificate-based version
        } else if (EV.CertName__c != null && EV.CertFile__c==null){
            jwt.cert = EV.CertName__c;
        } else {
            throw new EinsteinAuthException('Your custom settings are not set up properly.  Either CertFile or CertName should be populated');
        }

       // there's a default stting, but it's still configurable.  Uses the default if you aren't configured.
        if (EV.certificateIssuer__c != null){
            jwt.iss = EV.certificateIssuer__c;
        } else {
            jwt.iss = 'developer.force.com';
        }
        jwt.sub = EV.EinsteinUsername__c;
        jwt.aud = AUTH;
        jwt.validFor = integer.valueOf(EV.TokenExpirationTime__c);
        String access_token = JWTBearerFlow.getAccessToken(AUTH, jwt);

        system.debug(access_token);
        return access_token;
    }

    public class Prediction {
        public String label {get;set;}
        public Double probability {get;set;}
    }


    public class EinsteinAuthException extends Exception{}

    public static list<einsteinUtilities.Prediction> sendReqThenParsePredictions (HttpRequest req){
        List<EinsteinUtilities.Prediction> predictions = new List<EinsteinUtilities.Prediction>();

        Http http = new Http();
        req.setHeader('Connection', 'keep-alive');

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
                                    einsteinUtilities.Prediction probability = (einsteinUtilities.Prediction)parser.readValueAs(einsteinUtilities.Prediction.class);
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

    public static httpRequest standardPost(string access_token, map<string, string> params, string endpoint){
        if (access_token == null){
            access_token = einsteinUtilities.getAccessToken();
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

    public static httpRequest simpleRequest(string access_token, string endpoint, string method){
        if (access_token == null){
            access_token = einsteinUtilities.getAccessToken();
        }

        HttpRequest output = new HttpRequest();
        output.setMethod(method);
        output.setTimeout(120000);
        output.setHeader('Authorization','Bearer ' + access_token);
        output.setEndpoint(endpoint);

        return output;
    }

    public static string requestResponse(httpRequest req){
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug(res.getBody());
        return res.getBody();
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
}
