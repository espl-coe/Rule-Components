/*
* This class will decode and execute the passed RuleCondition send from ruleEngineController
*
* author : Neena Tiwari 
*/

public with sharing class DecodeRuleImplementatiion {

    public static final string TRUEVAL = 'true';
    public static final String FALSEVAL = 'false';

    // This method will decode all the rule & check for associated criterias
    public static void decodeRule(Map<Id,sObject> pSobjectMap,
                                  String pObjectName,
                                  Map<Id,sObject> pSobjectOldMap, 
                                  Map<String,String> ptopicNameRuleCond,
                                  String ptriggerEvent) {

        Boolean resultFor1,resultFor2,FinalResult;
        List<String> containsrule = new List<String>();
        List<String> containsOperator = new List<String>();
        Map<String,Criteria__c> CriteriaOfRuleMap = new Map<String,Criteria__c>();

        Schema.SObjectType Objectdetails = Schema.getGlobalDescribe().get(pObjectName);
        sobject object_instance = Objectdetails.newSObject();
        sobject object_instanceOld;
        
        for(sobject objItr : pSobjectMap.values()) {
            object_instance = objItr;
            if(pSobjectOldMap != null && pSobjectOldMap.get(objItr.Id)!= null)
                object_instanceOld = pSobjectOldMap.get(objItr.Id);
        }
        if(Objectdetails != null) {
            for(String ruleCondItr : RuleEngineController.ruleConditionMap.KeySet()) {
                containsrule.clear();
                containsOperator.clear();
                integer topVarRule = -1;
                integer topVarOperator = -1;
                
                //Replacing all spaces with empty String
                String ruleCond = RuleEngineController.ruleConditionMap.get(ruleCondItr).replaceAll('\\s+', '');
                
                //Replacing all 'Or' operator to '^'
                String ruleCond1 = ruleCond.replaceAll('(?i)or','^');
                
                //Replacing all 'AND' operator to '&'
                String ruleCond2 = ruleCond1.replaceAll('(?i)AND','&');
                
                String clubAllRuleCond = '' ;
                integer k = 0;
                integer j;
                integer leftCond;

                for(j=0;j<ruleCond2.length();j++) { 
                    if(ruleCond2.startsWith('(')) {
                        //checking for last character in Rule String
                        if(k == ruleCond2.length()-1 && ruleCond2.substring(j,j+1) == ')') { 
                            if(clubAllRuleCond != null && String.isNotEmpty(clubAllRuleCond)&& 
	                            String.isNotBlank(clubAllRuleCond)) {
	                            topVarRule++;
	                            containsrule.add(clubAllRuleCond);
	                            clubAllRuleCond = '';
                            }
                            //This condtion is to check when containsRule have only 1 value.
                            if(containsrule.size()>1){
                                String ruleCondFor1 = containsrule.get(topVarRule);
                                String ruleCondFor2 = containsrule.get(topVarRule-1);
                                String ruleOperator = containsOperator.get(topVarOperator); 

                                if(ruleOperator.equals('^')){
                                     FinalResult = runOrOperation(ruleCondFor1,
                                                                  ruleCondFor2,
                                                                  topVarRule,
                                                                  topVarOperator,
                                                                  containsrule,
                                                                  containsOperator,
                                                                  object_instance,
						                                          object_instanceOld,
						                                          Objectdetails,
						                                          ptriggerEvent,
						                                          ruleCondItr);
                                     //if contains rule have still some rule condtion which need to process.
                                     if(containsrule.size()> 1) {
                                        integer initialSizeOfStackforOR = containsrule.size()-1;
                                        for(leftCond = 0;leftCond<initialSizeOfStackforOR;leftCond++){
                                            ruleCondFor1 = containsrule.get(topVarRule);
                                            ruleCondFor2 = containsrule.get(topVarRule-1);
                                            ruleOperator = containsOperator.get(topVarOperator);
                                            if(containsOperator.get(topVarOperator) == '^'){
                                                FinalResult = boolean.valueof(ruleCondFor1) ||
                                                              boolean.valueof( ruleCondFor2);
                                                containsrule.remove(topVarRule);
                                                containsrule.remove(topVarRule-1);
                                                topVarRule--;
                                                topVarRule--;
                                                containsOperator.remove(topVarOperator);
                                                topVarOperator--;
                                                topVarRule++;
                                                containsrule.add(String.valueOf(FinalResult)); 
                                            }
                                            else{
                                                FinalResult = boolean.valueof(ruleCondFor1) && boolean.valueof( ruleCondFor2);
                                                containsrule.remove(topVarRule);
                                                containsrule.remove(topVarRule-1);
                                                topVarRule--;
                                                topVarRule--;
                                                containsOperator.remove(topVarOperator);
                                                topVarOperator--;
                                                topVarRule++;
                                                containsrule.add(String.valueOf(FinalResult));
                                            }
                                        }// for loop end
                                        
                                        if(containsrule.size() ==1 && FinalResult && FinalResult !=null){
                                            RuleEngineController.eventGenerator(FinalResult,object_instance,
                                                           RuleEngineController.ruleConditionMap.get(ruleCondItr),
                                                           ptopicNameRuleCond);
                                            containsrule.clear();
                                            containsOperator.clear();
                                        }
                                     }// containsRule size greater than 1 ends
                                     // Send the final value to eventGenerator when containsRule have on 1 value on their end position
                                     else{
                                        if(FinalResult && FinalResult !=null){
                                            RuleEngineController.eventGenerator(FinalResult,
                                                                                object_instance,
                                                                                RuleEngineController.ruleConditionMap.get(ruleCondItr),
                                                                                ptopicNameRuleCond);
                                            containsrule.clear();
                                            containsOperator.clear();
                                        }
                                     }
                                } //Or check end
                                else if(ruleOperator.equals('&')){
                                    FinalResult = runOrOperation(ruleCondFor1,
                                                                  ruleCondFor2,
                                                                  topVarRule,
                                                                  topVarOperator,
                                                                  containsrule,
                                                                  containsOperator,
                                                                  object_instance,
                                                                  object_instanceOld,
                                                                  Objectdetails,
                                                                  ptriggerEvent,
                                                                  ruleCondItr);
                                    if(containsrule.size()> 1){
                                        integer initialSizeOfStackforAND = containsrule.size()-1;
                                        for(leftCond = 0;leftCond<initialSizeOfStackforAND;leftCond++){
                                            ruleCondFor1 = containsrule.get(topVarRule);
                                            ruleCondFor2 = containsrule.get(topVarRule-1);
                                            ruleOperator = containsOperator.get(topVarOperator);
                                            
                                            if(containsOperator.get(topVarOperator) == '^'){
                                                FinalResult = boolean.valueof(ruleCondFor1) ||boolean.valueof( ruleCondFor2);
                                                containsrule.remove(topVarRule);
                                                containsrule.remove(topVarRule-1);
                                                topVarRule--;
                                                topVarRule--;
                                                containsOperator.remove(topVarOperator);
                                                topVarOperator--;
                                                topVarRule++;
                                                containsrule.add(String.valueOf(FinalResult)); 
                                            }
                                            else{
                                                FinalResult = boolean.valueof(ruleCondFor1) && boolean.valueof( ruleCondFor2);
                                                containsrule.remove(topVarRule);
                                                containsrule.remove(topVarRule-1);
                                                topVarRule--;
                                                topVarRule--;
                                                containsOperator.remove(topVarOperator);
                                                topVarOperator--;
                                                topVarRule++;
                                                containsrule.add(String.valueOf(FinalResult));
                                            }
                                        }
                                        if(containsrule.size() ==1 && FinalResult && FinalResult !=null){
                                            RuleEngineController.eventGenerator(FinalResult,
                                                                                object_instance,
                                                                                RuleEngineController.ruleConditionMap.get(ruleCondItr),
                                                                                ptopicNameRuleCond);
                                            containsrule.clear();
                                            containsOperator.clear();
                                        }
                                    }
                                    else{
                                        if(FinalResult && FinalResult !=null){
                                            RuleEngineController.eventGenerator(FinalResult,
                                                                                object_instance,
                                                                                RuleEngineController.ruleConditionMap.get(ruleCondItr),
                                                                                ptopicNameRuleCond);
                                            containsrule.clear();
                                            containsOperator.clear();
                                        }
                                    }
                                }
                             }//if containsRule siz is greater than 1
                             else {
                                 FinalResult = boolean.valueOf(containsrule.get(topVarRule));
                                 if(FinalResult && FinalResult !=null){
                                    RuleEngineController.eventGenerator(FinalResult,
                                                                        object_instance,
                                                                        RuleEngineController.ruleConditionMap.get(ruleCondItr),
                                                                        ptopicNameRuleCond);
                                    containsrule.clear();
                                    containsOperator.clear();
                                }
                             }
                        }// if ends for the last rule
                        // if String not reached it's end
                        else {
                             if(ruleCond2.substring(j,j+1).isAlphanumeric()){
                                clubAllRuleCond = clubAllRuleCond+ruleCond2.substring(j,j+1);
                             }     
                             if(ruleCond2.substring(j,j+1)=='^' ||      //If the current String is operator or ')'
                               ruleCond2.substring(j,j+1) == '&' || 
                               ruleCond2.substring(j,j+1) == ')'){
                                                                     //Adding all the rule in the map   
                                if(clubAllRuleCond != null && 
                                   String.isNotEmpty(clubAllRuleCond)&& 
                                   String.isNotBlank(clubAllRuleCond)){
                                    topVarRule++;
                                    containsrule.add(clubAllRuleCond);
                                    clubAllRuleCond = '';
                                }
                                                                    // Adding all the operator in the list
                                if(ruleCond2.substring(j,j+1)=='^'|| 
                                   ruleCond2.substring(j,j+1) == '&'){
                                    topVarOperator++;
                                    containsOperator.add(ruleCond2.substring(j,j+1));
                                }
                                                                    //Passing to the method if ')' tag is found
                                if(ruleCond2.substring(j,j+1) == ')') {
                                   String ruleCondFor1 = containsrule.get(topVarRule);
                                   String ruleCondFor2 = containsrule.get(topVarRule-1);
                                   String ruleOperator = containsOperator.get(topVarOperator);
                                    if(ruleOperator.equals('^')){
                                      FinalResult = runOrOperation(ruleCondFor1,
                                                                  ruleCondFor2,
                                                                  topVarRule,
                                                                  topVarOperator,
                                                                  containsrule,
                                                                  containsOperator,
                                                                  object_instance,
                                                                  object_instanceOld,
                                                                  Objectdetails,
                                                                  ptriggerEvent,
                                                                  ruleCondItr);  
                                    }
                                    else if(ruleOperator.equals('&')){
                                      FinalResult = runOrOperation(ruleCondFor1,
                                                                   ruleCondFor2,
                                                                   topVarRule,
                                                                   topVarOperator,
                                                                   containsrule,
                                                                   containsOperator,
                                                                   object_instance,
                                                                   object_instanceOld,
                                                                   Objectdetails,
                                                                   ptriggerEvent,
                                                                   ruleCondItr);
                                    }
                                }
                             } 
                        }
                    }//if start with('(') ends
                    // if the String don't start with have '(' 
                    else{
                        Boolean result = false;
                         if(ruleCond2.substring(j,j+1).isAlphanumeric()){
                                clubAllRuleCond = clubAllRuleCond+ruleCond.substring(j,j+1);
                            }
                            if(k == ruleCond2.length()-1){
                                if(clubAllRuleCond != null && String.isNotEmpty(clubAllRuleCond)&& String.isNotBlank(clubAllRuleCond)){
                                    containsrule.add(clubAllRuleCond);
                                    CriteriaOfRuleMap = RuleEngineController.CriteriaForRule(ruleCondItr,object_instance,object_instanceOld,
                                                                        Objectdetails,clubAllRuleCond,ptriggerEvent);
                                }
                                if(CriteriaOfRuleMap != null && !CriteriaOfRuleMap.isEmpty()){
                                    result = RuleEngineController.runCurrentRule(object_instance,object_instanceOld,CriteriaOfRuleMap.get(clubAllRuleCond)); 
                                    clubAllRuleCond = '';
                                }
                                if(result && result !=null){  
                                    RuleEngineController.eventGenerator(result,object_instance,RuleEngineController.ruleConditionMap.get(ruleCondItr),ptopicNameRuleCond);
                                    containsrule.clear();
                                    containsOperator.clear();
                                }
                            }       
                    } 
                     k++;
                }//for  String loop ends 
            }//ruleConditionmap for loop ends
        }//Objectdetails if end
    }//decodeRule ends
    
   
    
    public static Boolean runOrOperation(String ruleCondFor1,
                                         String ruleCondFor2,
                                         Integer topVarRule,
                                         Integer topVarOperator,
                                         list<String> containsrule,
                                         list<String> containsOperator,
                                         sobject object_instance,
                                         sobject object_instanceOld,
                                         Schema.SObjectType Objectdetails,
                                         String ptriggerEvent,
                                         string ruleCondItr){
        Boolean resultFor1, resultFor2;
        Integer leftCond;
	    resultFor1 = getResultFor1stRule(ruleCondFor1,
                                         object_instance,
                                         object_instanceOld,
                                         Objectdetails,
                                         ptriggerEvent,
                                         ruleCondItr);
        resultFor2 = getResultFor2ndRule(ruleCondFor2,
                                         object_instance,
                                         object_instanceOld,
                                         Objectdetails,
                                         ptriggerEvent,
                                         ruleCondItr);
	    Boolean ResultOfOr = resultFor1!= null && resultFor2 !=null ? resultFor1 || resultFor2:false;
	    containsrule.remove(topVarRule);
	    containsrule.remove(topVarRule-1);
	    topVarRule--;
	    topVarRule--;
	    containsOperator.remove(topVarOperator);
	    topVarOperator--;
	    topVarRule++;
	    containsrule.add(String.valueOf(ResultOfOr));   
        if(containsrule.size()> 1){
            integer initialSizeOfStackforOR = containsrule.size()-1;
            for(leftCond = 0;leftCond<initialSizeOfStackforOR;leftCond++){
                String tempRuleCondFor1 = containsrule.get(topVarRule);
                String tempRuleCondFor2 = containsrule.get(topVarRule-1);
                String tempRuleOperator = containsOperator.get(topVarOperator);

                if(tempRuleOperator == '^'){
                     resultFor1 = getResultFor1stRule(tempRuleCondFor1,
			                                          object_instance,
			                                          object_instanceOld,
			                                          Objectdetails,
			                                          ptriggerEvent,
			                                          ruleCondItr);
                    resultFor2 = getResultFor2ndRule(tempRuleCondFor2,
			                                         object_instance,
			                                         object_instanceOld,
			                                         Objectdetails,
			                                         ptriggerEvent,
			                                         ruleCondItr);
                    ResultOfOr = resultFor1!= null && resultFor2 !=null ? resultFor1 || resultFor2:false;
                    containsrule.remove(topVarRule);
                    containsrule.remove(topVarRule-1);
                    topVarRule--;
                    topVarRule--;
                    containsOperator.remove(topVarOperator); 
                    topVarOperator--;
                    topVarRule++;
                    containsrule.add(String.valueOf(ResultOfOr)); 
                }
                else{
                    resultFor1 = getResultFor1stRule(ruleCondFor1,
                                                      object_instance,
                                                      object_instanceOld,
                                                      Objectdetails,
                                                      ptriggerEvent,
                                                      ruleCondItr);
                    resultFor2 = getResultFor2ndRule(ruleCondFor2,
                                                     object_instance,
                                                     object_instanceOld,
                                                     Objectdetails,
                                                     ptriggerEvent,
                                                     ruleCondItr);
                    ResultOfOr = resultFor1!= null && resultFor2 !=null ? resultFor1 && resultFor2:false;
                    containsrule.remove(topVarRule);
                    containsrule.remove(topVarRule-1);
                    topVarRule--;
                    topVarRule--;
                    containsOperator.remove(topVarOperator); 
                    topVarOperator--;
                    topVarRule++;
                    containsrule.add(String.valueOf(ResultOfOr)); 
                }
            }     
        }// containsRule size greater than 1 ends
         return ResultOfOr;
    }

    public static Boolean runAndOperation(String ruleCondFor1,
                                         String ruleCondFor2,
                                         Integer topVarRule,
                                         Integer topVarOperator,
                                         list<String> containsrule,
                                         list<String> containsOperator,
                                         sobject object_instance,
                                         sobject object_instanceOld,
                                         Schema.SObjectType Objectdetails,
                                         String ptriggerEvent,
                                         string ruleCondItr){
        Boolean resultFor1, resultFor2;
        Integer leftCond;
        resultFor1 = getResultFor1stRule(ruleCondFor1,
                                         object_instance,
                                         object_instanceOld,
                                         Objectdetails,
                                         ptriggerEvent,
                                         ruleCondItr);
        resultFor2 = getResultFor2ndRule(ruleCondFor2,
                                         object_instance,
                                         object_instanceOld,
                                         Objectdetails,
                                         ptriggerEvent,
                                         ruleCondItr);
        Boolean ResultOfOr = resultFor1!= null && resultFor2 !=null ? resultFor1 || resultFor2:false;
        containsrule.remove(topVarRule);
        containsrule.remove(topVarRule-1);
        topVarRule--;
        topVarRule--;
        containsOperator.remove(topVarOperator);
        topVarOperator--;
        topVarRule++;
        containsrule.add(String.valueOf(ResultOfOr));   
        if(containsrule.size()> 1){
            integer initialSizeOfStackforOR = containsrule.size()-1;
            for(leftCond = 0;leftCond<initialSizeOfStackforOR;leftCond++){
                String tempRuleCondFor1 = containsrule.get(topVarRule);
                String tempRuleCondFor2 = containsrule.get(topVarRule-1);
                String tempRuleOperator = containsOperator.get(topVarOperator);

                if(tempRuleOperator == '^'){
                     resultFor1 = getResultFor1stRule(tempRuleCondFor1,
                                                      object_instance,
                                                      object_instanceOld,
                                                      Objectdetails,
                                                      ptriggerEvent,
                                                      ruleCondItr);
                    resultFor2 = getResultFor2ndRule(tempRuleCondFor2,
                                                     object_instance,
                                                     object_instanceOld,
                                                     Objectdetails,
                                                     ptriggerEvent,
                                                     ruleCondItr);                    
                    ResultOfOr = resultFor1!= null && resultFor2 !=null ? resultFor1 || resultFor2:false;
                    containsrule.remove(topVarRule);
                    containsrule.remove(topVarRule-1);
                    topVarRule--;
                    topVarRule--;
                    containsOperator.remove(topVarOperator); 
                    topVarOperator--;
                    topVarRule++;
                    containsrule.add(String.valueOf(ResultOfOr)); 
                }
                else{
                    resultFor1 = getResultFor1stRule(ruleCondFor1,
                                                      object_instance,
                                                      object_instanceOld,
                                                      Objectdetails,
                                                      ptriggerEvent,
                                                      ruleCondItr);
                    resultFor2 = getResultFor2ndRule(ruleCondFor2,
                                                     object_instance,
                                                     object_instanceOld,
                                                     Objectdetails,
                                                     ptriggerEvent,
                                                     ruleCondItr);
                    ResultOfOr = resultFor1!= null && resultFor2 !=null ? resultFor1 && resultFor2:false;
                    containsrule.remove(topVarRule);
                    containsrule.remove(topVarRule-1);
                    topVarRule--;
                    topVarRule--;
                    containsOperator.remove(topVarOperator); 
                    topVarOperator--;
                    topVarRule++;
                    containsrule.add(String.valueOf(ResultOfOr)); 
                }
            }    
            system.debug('containsrule '+containsrule);
        }// containsRule size greater than 1 ends
     return ResultOfOr;
    }
 
    public static Boolean getResultFor1stRule(String pRuleCondfor1,
                                              sobject object_instance,
                                              sobject object_instanceOld,
                                              Schema.SObjectType Objectdetails,
                                              String ptriggerEvent,
                                              string ruleCondItr) {

         Map<String,Criteria__c> CriteriaOfRuleMap = new Map<String,Criteria__c>();
         boolean resultFor1;
         if(pRuleCondfor1 != null && !pRuleCondfor1.equalsIgnoreCase(TRUEVAL) && 
           !pRuleCondfor1.equalsIgnoreCase(FALSEVAL)) {
              CriteriaOfRuleMap = RuleEngineController.CriteriaForRule(ruleCondItr,
                                                                       object_instance,
                                                                       object_instanceOld,
                                                                       Objectdetails,
                                                                       pRuleCondfor1,
                                                                       ptriggerEvent);
         }
         resultFor1 = pRuleCondfor1 != null && pRuleCondfor1.equalsIgnoreCase(TRUEVAL)||
                        pRuleCondfor1.equalsIgnoreCase(FALSEVAL)?
                      boolean.valueOf(pRuleCondfor1):
                      RuleEngineController.runCurrentRule(object_instance,
                                                          object_instanceOld,
                                                          CriteriaOfRuleMap.get(pRuleCondfor1));
       return resultFor1;
}

    public static Boolean getResultFor2ndRule(String pRuleCondfor2,
                                              sobject object_instance,
                                              sobject object_instanceOld,
                                              Schema.SObjectType Objectdetails,
                                              String ptriggerEvent,
                                              string ruleCondItr) {

         Map<String,Criteria__c> CriteriaOfRuleMap = new Map<String,Criteria__c>();
         boolean resultFor2;
         if(pRuleCondfor2 != null && !pRuleCondfor2.equalsIgnoreCase(TRUEVAL) && 
           !pRuleCondfor2.equalsIgnoreCase(FALSEVAL)) {
              CriteriaOfRuleMap = RuleEngineController.CriteriaForRule(ruleCondItr,
                                                                       object_instance,
                                                                       object_instanceOld,
                                                                       Objectdetails,
                                                                       pRuleCondfor2,
                                                                       ptriggerEvent);
         }
         resultFor2 = pRuleCondfor2 != null && pRuleCondfor2.equalsIgnoreCase(TRUEVAL)||
                        pRuleCondfor2.equalsIgnoreCase(FALSEVAL)?
                      boolean.valueOf(pRuleCondfor2):
                      RuleEngineController.runCurrentRule(object_instance,
                                                          object_instanceOld,
                                                          CriteriaOfRuleMap.get(pRuleCondfor2));
       return resultFor2;
    }
}