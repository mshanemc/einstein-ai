//EinsteinLanguage.languageFeedback(String text, String label, String modelId, String token)
system.debug(
	EinsteinLanguage.languageFeedback(
		'My questions is about electrical',
		'Electrical',
		'2RXZRP2VQRJZU4A2LZAM56K2DA',
		Vision.getAccessToken())
);

//typical error:
//USER_DEBUG [2]|DEBUG|{"message":"Unable to find entity with ID 2RXZRP2VQRJZU4A2LZAM56K2DA  "}
