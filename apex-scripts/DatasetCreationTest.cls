//public static string createDataset(string SFDCmodelId, string obj, string src, string classify){
ContentDistribution CD = (ContentDistribution)JSON.deserialize(EinsteinLanguage.createDataset('a034100000zU7aIAAS', 'Case', 'Subject', 'Reason'), ContentDistribution.class);
system.debug(CD);

//public static string createDatasetPart2(string SFDCmodelId, string CDID){
EinsteinLanguage.createDatasetFuture('a034100000zU7aIAAS', CD.id);

//typical error:
// USER_DEBUG [121]|DEBUG|{"message":"Supported language dataset types: [text-sentiment, text-intent-ner, text-intent, text-qa]"}