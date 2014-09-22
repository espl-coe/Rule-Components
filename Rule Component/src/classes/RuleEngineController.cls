/*
 *	Description : This class with validate all the topic associated rules & rule criterias.
 */
public with sharing class RuleEngineController {
	
	public static Map<String,Topic__c> topicMap = new Map<String,Topic__c>();
	private static final String EQUALS = 'equals';
	// This method will validate all the associated criterias of sObject
	public static void checkForCriterias(Map<Id,sObject> pSobjectMap,String pObjectName,String pTriggerEvent){
		
		// Map of topic name & list of associated criterias
		Map<String,List<Criteria__c>> ruleCriteriaMap = new Map<String,List<Criteria__c>>();
		Set<String> topicSet = new Set<String>();
		System.debug('pSobjectMap===='+pSobjectMap);
		for(Rule_Criterias__c ruleCriteriasItr : [SELECT Id,
														 Rule__r.id,
														 Rule__r.Rule_Condition__c,
														 Rule__r.Topic_Name__c,
														 Rule__r.TriggerEvents__c,
														 Rule__r.Object_Name__c,
														 Criteria__r.isActive__c,	
														 Criteria__r.Field_Name__c,
														 Criteria__r.Operator__c,
														 Criteria__r.Value__c,
														 Criteria__r.Rule_No__c,
														 Criteria__r.ValueType__c
														 FROM Rule_Criterias__c 
														 WHERE Criteria__r.isActive__c=true AND
														  	   Rule__r.Object_Name__c =:pObjectName AND
														  	   Rule__r.TriggerEvents__c INCLUDES (:pTriggerEvent)]
														  	   ){
				System.debug('ruleCriteriasItr===='+ruleCriteriasItr);									  
			if(ruleCriteriaMap.containsKey(ruleCriteriasItr.Rule__r.Topic_Name__c) && ruleCriteriaMap.get(ruleCriteriasItr.Rule__r.Topic_Name__c)!=null && String.isNotBlank(ruleCriteriasItr.Rule__r.Topic_Name__c)){
				ruleCriteriaMap.get(ruleCriteriasItr.Rule__r.Topic_Name__c).add(new Criteria__c(Field_Name__c=ruleCriteriasItr.Criteria__r.Field_Name__c,
																			   Operator__c =ruleCriteriasItr.Criteria__r.Operator__c,
																			   Value__c=ruleCriteriasItr.Criteria__r.Value__c,
																			   Rule_No__c=ruleCriteriasItr.Criteria__r.Rule_No__c,
																			   ValueType__c=ruleCriteriasItr.Criteria__r.ValueType__c));
				topicSet.add(ruleCriteriasItr.Rule__r.Topic_Name__c);
			}
			else if(String.isNotBlank(ruleCriteriasItr.Rule__r.Topic_Name__c)){
				ruleCriteriaMap.put(ruleCriteriasItr.Rule__r.Topic_Name__c,new List<Criteria__c>{(new Criteria__c(Field_Name__c=ruleCriteriasItr.Criteria__r.Field_Name__c,
																			   Operator__c =ruleCriteriasItr.Criteria__r.Operator__c,
																			   Value__c=ruleCriteriasItr.Criteria__r.Value__c,
																			   Rule_No__c=ruleCriteriasItr.Criteria__r.Rule_No__c,
																			   ValueType__c=ruleCriteriasItr.Criteria__r.ValueType__c))});
				topicSet.add(ruleCriteriasItr.Rule__r.Topic_Name__c);
			}
		}// end - for loop
		
		if(!ruleCriteriaMap.isEmpty()){
			RuleEngineController.decodeRule(ruleCriteriaMap,pSobjectMap,pObjectName);
		}
	}
	
	// This method will decode all the rule & check for associated criterias
	public static void decodeRule(Map<String,List<Criteria__c>> pRuleCriteriaMap,Map<Id,sObject> pSobjectMap,String pObjectName){
		
		Schema.SObjectType res = Schema.getGlobalDescribe().get(pObjectName);
		System.debug('res===='+res);	
		if(res != null){
			Schema.Describesobjectresult dsr = Schema.getGlobalDescribe().get(pObjectName).getDescribe();
	        Map<String, Schema.SObjectField> sObjMap = dsr.fields.getMap();
	        sobject object_instance = res.newSObject();
	        
			for(sObject objItr : pSobjectMap.values()){
				object_instance = objItr;
				System.debug('object_instance===='+object_instance);	
				for(String topicNameItr : pRuleCriteriaMap.keySet()){
					
					if(pRuleCriteriaMap.get(topicNameItr) != null && !pRuleCriteriaMap.get(topicNameItr).isEmpty()){
						List<Criteria__c> criteriaLst = pRuleCriteriaMap.get(topicNameItr);
						
						for(Criteria__c criteriaItr : criteriaLst){
							if(criteriaItr.Operator__c == EQUALS && object_instance.get(criteriaItr.Field_Name__c) == Boolean.valueOf(criteriaItr.Value__c)){
								System.debug('Success!');
								
							}
						}
					}
				}
			}
		}
	}
	
	// This method will check for datatype & return true if matches else false.
	public static void checkforDatatype(String pDatatype,String pLeftParam,String pRighParam){
		
	}
}