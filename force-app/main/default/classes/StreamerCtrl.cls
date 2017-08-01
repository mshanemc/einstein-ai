public class StreamerCtrl {
	
    @AuraEnabled
    public static String sessionId() {
        return UserInfo.getSessionId();
    }

    
}