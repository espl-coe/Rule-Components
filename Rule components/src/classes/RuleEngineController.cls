/*
* This class will fetch,decode and execute the RueCondition mentioned on Rule and send the 
* final boolean result to eventGenerator which will create Event, if true.  
*
* author : Neena Tiwari 
*/
public with sharing class RuleEngineController {
        
    public static Map<String,String> criteriaFieldNameWithDT = new Map<String,String>();
    public static Map<String,List<Criteria__c>> ruleCriteriaMap = new Map<String,List<Criteria__c>>();
    public static Map<String,String> ruleConditionMap = new Map<String,String>();
    public static Map<string,string> ruleConditionSystemIdMap = new Map<String,string>();
    private static final String EQUALS =        'equals';
    private static final String DT_DOUBLE =     'Double';
    private static final String DT_CURRENCY =   'Currency';
    private static final String DT_DATETIME =   'Datetime';
    private static final String DT_BOOLEAN =    'Boolean';
    private static final String DT_PERCENT =    'PERCENT';
    private static final String DT_PICKLIST =   'PICKLIST';
    private static final String DT_Date =       'Date';
    private static final String APINAME =       'API';
    private static final String NOTEQUALS =     'not equal to';
    private static final String GREATERTHAN =   'greater than';
    private static final String LESSTHAN =      'less than';
    private static final String GREATEROREQUAL ='greater Or Equal';
    private static final String LESSOREQUAL =   'less Or Equal';
    private static final String CONTAINS =      'Contains';
    private static final String NOTCONTAIN =    'Does not Contain';
    private static final String STARTSWITH =    'Starts With';
    private static final String ISCHANGED =     'ischanged';

    // This method will validate all the associated criterias of sObject
    public static void checkForCriterias(Map<Id,sObject> pSobjectMap,Map<Id,sobject> pSobjectOldMap,
                                         String pObjectName,String pTriggerEvent) {

	    // Map of topic name & list of associated criterias
	
	    Map<String,String> topicNameRuleCond = new Map<String,String>();
	    ruleCriteriaMap.clear();  
	    ruleConditionMap.clear();
		ruleConditionSystemIdMap.Clear();
	    for(Rule_Criterias__c ruleCriteriasItr : [SELECT Id,
	                                                     Rule__r.id,
	                                                     Rule__r.Rule_Condition__c,
	                                                     Rule__r.Topic_Name__c,
	                                                     Rule__r.TriggerEvents__c,
	                                                     Rule__r.Object_Name__c,
	                                                     Rule__r.ENS_System__c,
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
	                                                               ) {
	        if(ruleCriteriaMap.containsKey(ruleCriteriasItr.Rule__r.Topic_Name__c) && 
	            ruleCriteriaMap.get(ruleCriteriasItr.Rule__r.Topic_Name__c)!=null && 
	            String.isNotBlank(ruleCriteriasItr.Rule__r.Topic_Name__c)) {
	                    
	            ruleCriteriaMap.get(ruleCriteriasItr.Rule__r.Topic_Name__c).
	                   add(new Criteria__c(
                               Field_Name__c = ruleCriteriasItr.Criteria__r.Field_Name__c,
                               Operator__c = ruleCriteriasItr.Criteria__r.Operator__c,
                               Value__c = ruleCriteriasItr.Criteria__r.Value__c,
                               Rule_No__c = ruleCriteriasItr.Criteria__r.Rule_No__c,
                               ValueType__c = ruleCriteriasItr.Criteria__r.ValueType__c
                            )
                       );
	            ruleConditionMap.put(ruleCriteriasItr.Rule__r.Topic_Name__c,
	                                 ruleCriteriasItr.Rule__r.Rule_Condition__c);
	            topicNameRuleCond.put(ruleCriteriasItr.Rule__r.Rule_Condition__c,
	                                  ruleCriteriasItr.Rule__r.Topic_Name__c);
                ruleConditionSystemIdMap.put(ruleCriteriasItr.Rule__r.Rule_Condition__c,
                							 ruleCriteriasItr.Rule__r.ENS_System__c);
               	system.debug('ruleConditionSystemIdMap'+ruleConditionSystemIdMap);
	        }
	        else if(String.isNotBlank(ruleCriteriasItr.Rule__r.Topic_Name__c)){
	            ruleCriteriaMap.put(ruleCriteriasItr.Rule__r.Topic_Name__c,
	                                   new List<Criteria__c>{(
	                                      new Criteria__c(
                                              Field_Name__c=ruleCriteriasItr.Criteria__r.Field_Name__c,
                                              Operator__c =ruleCriteriasItr.Criteria__r.Operator__c,
		                                      Value__c=ruleCriteriasItr.Criteria__r.Value__c,
		                                      Rule_No__c=ruleCriteriasItr.Criteria__r.Rule_No__c,
                                              ValueType__c=ruleCriteriasItr.Criteria__r.ValueType__c
                                          )
                                       )}
                                   );
                ruleConditionMap.put(ruleCriteriasItr.Rule__r.Topic_Name__c,
                                     ruleCriteriasItr.Rule__r.Rule_Condition__c);
                topicNameRuleCond.put(ruleCriteriasItr.Rule__r.Rule_Condition__c,
                                      ruleCriteriasItr.Rule__r.Topic_Name__c);
                ruleConditionSystemIdMap.put(ruleCriteriasItr.Rule__r.Rule_Condition__c,
                							 ruleCriteriasItr.Rule__r.ENS_System__c);
            	system.debug('ruleConditionSystemIdMapElse'+ruleConditionSystemIdMap);
            }
        }// end - for loop
        if(!ruleCriteriaMap.isEmpty()&& !ruleConditionMap.isEmpty()){
            DecodeRuleImplementatiion.decodeRule(pSobjectMap,pObjectName,
                                                pSobjectOldMap,topicNameRuleCond,pTriggerEvent);
        }
    }

    public static Map<String,Criteria__c> CriteriaForRule (String topicName,
                                                           sobject pObject_instanceNew,
                                                           sobject pObject_instanceOld,
                                                           Schema.SObjectType pObjectName,
                                                           String pCurrentRule,
                                                           String pCurrentTriggerEvent){

        Map<String,Criteria__c> criteriaRelToCurrentRule = new Map<String,Criteria__c>();
        Schema.Describesobjectresult objDetails = pObjectName.getDescribe();
        Map<String, Schema.SObjectField> sObjMap = objDetails.fields.getMap();
        List<Criteria__c> pCriteriaLst = ruleCriteriaMap.get(topicName);
        pCurrentTriggerEvent = pCurrentTriggerEvent.replaceAll('\\s+', '');

        if(!pCriteriaLst.isEmpty() && pCriteriaLst!=null) {
            for(Criteria__c criteriaItr : pCriteriaLst) {
 
                 // This if call when insert is called
                 if(criteriaItr.Field_Name__c != Null && 
                    pObject_instanceNew.get(criteriaItr.Field_Name__c) != null && 
                    pCurrentRule.equalsIgnoreCase(String.valueof(criteriaItr.Rule_No__c)) &&
                    pCurrentTriggerEvent.containsIgnoreCase('insert')&& pObject_instanceOld == null) {
	
                        Schema.SObjectField objectField = sObjMap.get(criteriaItr.Field_Name__c);
                        criteriaRelToCurrentRule = fetchDataType(objectField,pCurrentRule,criteriaItr); 
                        return criteriaRelToCurrentRule;
                 }
                 // This if call when update is called
                 else if(pObject_instanceOld != Null && 
                         pCurrentTriggerEvent.containsIgnoreCase('update') && 
                         pObject_instanceNew.get(criteriaItr.Field_Name__c) != null  &&
                         pObject_instanceNew.get(criteriaItr.Field_Name__c) != pObject_instanceOld.get(criteriaItr.Field_Name__c)) {
	
                        Schema.SObjectField objectField = sObjMap.get(criteriaItr.Field_Name__c); 
                        criteriaRelToCurrentRule = fetchDataType(objectField,pCurrentRule,criteriaItr); 
                        return criteriaRelToCurrentRule;
                 }
            }
            return criteriaRelToCurrentRule; 
        }
        return criteriaRelToCurrentRule;    
    }//CriteriaForRule ends

    public static Map<String,Criteria__c> fetchDataType(Schema.SObjectField pSobjectFieldDetails, 
                                                        String pCurrentRule,Criteria__c criteriaItr) {
        Map<String,Criteria__c> criteriaRelToCurrentRule = new Map<String,Criteria__c>();

        schema.DescribeFieldResult fieldDescription = pSobjectFieldDetails.getDescribe();
        if(fieldDescription.isAccessible() && fieldDescription.isCreateable()){ 
            criteriaFieldNameWithDT.put(fieldDescription.getName(),String.valueOf(fieldDescription.getType()));
        }
        if(String.isNotBlank(pCurrentRule) && String.isNotEmpty(pCurrentRule)){
            criteriaRelToCurrentRule.put(pCurrentRule,criteriaItr);
            return criteriaRelToCurrentRule;
        }
        return criteriaRelToCurrentRule;
     }

    // This method will check for datatype & return field value with converted value, if matches.
    public static boolean runCurrentRule(sobject psobjNew,sobject psobjOld,Criteria__c pcriteria) {

        Criteria__c CriteriaValue = pcriteria;

        if(CriteriaValue != null){
            String DataType = CriteriaValue != null && criteriaFieldNameWithDT.containsKey(CriteriaValue.Field_Name__c) && 
                              criteriaFieldNameWithDT.get(CriteriaValue.Field_Name__c) != null ?
                              criteriaFieldNameWithDT.get(CriteriaValue.Field_Name__c) : Null;
                          
            String leftParenthesis = String.valueOf(psobjNew.get(CriteriaValue.Field_Name__c));
            String  rightParenthesis = CriteriaValue.ValueType__c == APINAME? 
                          String.valueOf(psobjNew.get(CriteriaValue.Value__c)):
                          String.ValueOf(CriteriaValue.Value__c);
                          
            if(CriteriaValue.Operator__c.equalsIgnoreCase(EQUALS)){
                if(checkForDatatype(DataType,leftParenthesis,rightParenthesis,CriteriaValue.Operator__c)){
                    return true;
               }
               else return false;
            }//Equals Ends
            
            else if(CriteriaValue.Operator__c.equalsIgnoreCase(NOTEQUALS)){
                if(checkForDatatype(DataType,leftParenthesis,rightParenthesis,CriteriaValue.Operator__c)){
                    return true;
                }
                else return false;
            }// not equal to ends
            
            else if(CriteriaValue.Operator__c.equalsIgnoreCase(GREATERTHAN)){
                if(checkForDatatype(DataType,leftParenthesis,rightParenthesis,CriteriaValue.Operator__c)){
                    return true;
                }
                 else return false;
            }//greater than ends
            
            else if(CriteriaValue.Operator__c.equalsIgnoreCase(LESSTHAN)){
                if(checkForDatatype(DataType,leftParenthesis,rightParenthesis,CriteriaValue.Operator__c)){
                    return true;
                }
                else return false;
            }// less than ends
            
            else if(CriteriaValue.Operator__c.equalsIgnoreCase(GREATEROREQUAL)){
                if(checkForDatatype(DataType,leftParenthesis,rightParenthesis,CriteriaValue.Operator__c)){
                    return true;
                }
                else return false;
            }// greater or equals ends
            
            else if(CriteriaValue.Operator__c.equalsIgnoreCase(LESSOREQUAL)){
                if(checkForDatatype(DataType,leftParenthesis,rightParenthesis,CriteriaValue.Operator__c)){
                    return true;
                }
                else return false;
            }// less or equals ends
            
            else if(CriteriaValue.Operator__c.equalsIgnoreCase(CONTAINS)){
                if(checkForDatatype(DataType,leftParenthesis,rightParenthesis,CriteriaValue.Operator__c)){
                    return true;
               }
               else return false;
            }// contains ends
            
            else if(CriteriaValue.Operator__c.equalsIgnoreCase(NOTCONTAIN)){
                if(checkForDatatype(DataType,leftParenthesis,rightParenthesis,CriteriaValue.Operator__c)){
                    return true;
                }
                else return false;
            }// does not contains ends
            
            else if(CriteriaValue.Operator__c.equalsIgnoreCase(STARTSWITH)){
                if(checkForDatatype(DataType,leftParenthesis,rightParenthesis,CriteriaValue.Operator__c)){
                    return true;        
               }
               else return false;       
            }//starts With ends
            
            else if(CriteriaValue.Operator__c.equalsIgnoreCase(ISCHANGED)){
                Boolean runTrueorFalse;
                if(psobjOld != null){
                    runTrueorFalse = psobjNew.get(CriteriaValue.Field_Name__c) != 
                                     psobjOld.get(CriteriaValue.Field_Name__c) ? 
                                     true :
                                     false;
                    return  runTrueorFalse;
                }
                else 
                return runTrueorFalse;
            }// Ischanged ends
        
        return null;
        }
         return null;
    }//runCurrentRule method ends

    // This method will check for datatype & return field value with converted value, if matches.
    public static boolean checkForDatatype(String dataType,String leftParenthesis,String rightParenthesis,String operator) {

            if(dataType == DT_DOUBLE ||dataType == DT_CURRENCY || dataType == DT_PERCENT){
                if(operator.equalsIgnorecase(GREATERTHAN) && double.valueOf(leftParenthesis)> double.valueOf(rightParenthesis)){
                    return true;
                 }
                 else if(operator.equalsIgnorecase(GREATEROREQUAL) && double.valueOf(leftParenthesis)>=double.valueOf(rightParenthesis)){
                    return true;
                 }
                 else if(operator.equalsIgnorecase(LESSTHAN) && double.valueOf(leftParenthesis)<double.valueOf(rightParenthesis)){
                    return true;
                 }
                 else if(operator.equalsIgnorecase(LESSOREQUAL) && double.valueOf(leftParenthesis)<=double.valueOf(rightParenthesis)){
                    return true;
                 }
                 else{
                    return false;
                 }
                return null;
            }//double,currency,percent check

            else if(dataType == DT_BOOLEAN){
                 if(operator.equalsIgnorecase(EQUALS)&& Boolean.valueOf(leftParenthesis) == Boolean.valueOf(rightParenthesis)){
                    return true;
                 }
                 else if(operator.equalsIgnorecase(NOTEQUALS)&& Boolean.valueOf(leftParenthesis) != Boolean.valueOf(rightParenthesis)){
                    return true;
                 }
                 else{
                    return false;
                 }
                return null;
            }// boolean check

            else if(dataType == DT_DATETIME){
                DateTime dtObjForLeft = DateTime.ValueOf(leftParenthesis);
                DateTime dtObjForRight = DateTime.ValueOf(rightParenthesis);
                if(operator.equalsIgnorecase(EQUALS) && dtObjForLeft == dtObjForRight){
                    return true;
                 }
                 else if(operator.equalsIgnorecase(NOTEQUALS) && dtObjForLeft != dtObjForRight){
                    return true;
                 }
                 else if(operator.equalsIgnorecase(GREATERTHAN) && dtObjForLeft > dtObjForRight){
                    return true;
                 }
                 else if(operator.equalsIgnorecase(GREATEROREQUAL) && dtObjForLeft >= dtObjForRight){
                    return true;
                 }
                 else if(operator.equalsIgnorecase(LESSTHAN) && dtObjForLeft < dtObjForRight){
                    return true;
                 }
                 else if(operator.equalsIgnorecase(LESSOREQUAL) && dtObjForLeft <= dtObjForRight){
                    return true;
                 }
                 else{
                    return false;
                 }
                return null;
            }//DateTime check

            else if(dataType == DT_DATE){
                Date dObjForLeft = Date.ValueOf(leftParenthesis);
                Date dObjForRight = Date.ValueOf(rightParenthesis);
                if(operator.equalsIgnorecase(EQUALS) && dObjForLeft == dObjForRight){
                    return true;
                }
                else if(operator.equalsIgnorecase(NOTEQUALS) && dObjForLeft != dObjForRight){
                    return true;
                }
                else if(operator.equalsIgnorecase(GREATERTHAN) && dObjForLeft > dObjForRight){
                    return true;
                }
                else if(operator.equalsIgnorecase(GREATEROREQUAL) && dObjForLeft >= dObjForRight){
                    return true;
                }
                else if(operator.equalsIgnorecase(LESSTHAN) && dObjForLeft < dObjForRight){
                    return true;
                }
                else if(operator.equalsIgnorecase(LESSOREQUAL) && dObjForLeft <= dObjForRight){
                    return true;
                }
                else{
                    return false;
                }
                return null;
            }//Date Check

            else{
                if(operator.equalsIgnorecase(EQUALS) && String.valueOf(leftParenthesis) == String.valueOf(rightParenthesis)){
                    return true;
                 }    
                 if(operator.equalsIgnorecase(NOTEQUALS) && String.valueOf(leftParenthesis) != String.valueOf(rightParenthesis)){
                    return true;
                 }
                 if(operator.equalsIgnorecase(CONTAINS) && leftParenthesis.Contains(rightParenthesis)){
                    return true;
                 }
                 if(operator.equalsIgnorecase(NOTCONTAIN) && !leftParenthesis.Contains(rightParenthesis)){
                    return true;
                 }
                 if(operator.equalsIgnorecase(NOTCONTAIN) && leftParenthesis.startsWith(rightParenthesis)){
                    return true;
                 }
                 else{
                    return false;
                 }
                return null;
            }//String check       
        return null;
    }//checkForDatatype method ends

      
}// RuleEngineController ends