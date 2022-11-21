global class Batch_BluePay_FileGen implements Database.Batchable<sObject>,Database.Stateful{
    global String query = '';
    global Static String bp1 = '';
    global Static String bp2 = '';
    global Static String bp3 = '';
    global Static String bp4 = '';
    global Static String headerValues = '';
    global List<String> csvRowValues = new List<String>();
    global Static List<String> rowsList = new List<String>();
    
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        query = 'SELECT Id,Name FROM  Account LIMIT 10';
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        
        String res = CLS_BluePay_DocGenCallout.generateBluePayFile();
        System.debug('#$$$$$$$$$$$$$$$$$###'+res);
        System.debug('&&&&&&&&&::::::::::::'+JSON.serialize(res));
        
        Map<String, Object> meta = (Map<String, Object>)JSON.deserializeUntyped(res);
        meta.remove('GlobalParams');
        
        System.debug('!@!@!@:::'+meta);
        
        String bluepaystaticRowString = '';
        String lptRowString = '';
        Map<String, Object> bluepaystaticMap = new Map<String, Object>();
        Map<String, Object> bluepaystaticMapcloned = new Map<String, Object>();
        Map<String, Object> lptMapCloned = new Map<String, Object>();
        Map<String, Object> lptmap = new Map<String, Object>();
        Map<String, Object> headerMap = new Map<String, Object>();
        List<Map<String, Object>> mapOfBPList = new List<Map<String, Object>>();
        List<Map<String, Object>> mapOfLPTDList = new List<Map<String, Object>>();
        Set<Id> lptRecIdSet = new Set<Id>();
        Map<String, Object> lptMapVal = new Map<String, Object>();
        for(String csvColHeader : meta.keySet()){
            String headValues = JSON.serialize(meta.get(csvColHeader));
            headerMap = (Map<String, Object>)JSON.deserializeUntyped(headValues);
            if(getsObjectName(csvColHeader) == 'BluePay__c'){
                String bprec = JSON.serialize(meta.get(csvColHeader));
                bluepaystaticMap = (Map<String, Object>)JSON.deserializeUntyped(bprec);
                bluepaystaticMapcloned = bluepaystaticMap.clone();
            }else if(getsObjectName(csvColHeader) == 'loan__Loan_Payment_Transaction__c'){  
                String LPTRec = JSON.serialize(meta.get(csvColHeader));
                lptMapVal = (Map<String, Object>)JSON.deserializeUntyped(LPTRec);
                System.debug('LLLLL:::'+lptMapVal);
                lptMapCloned = lptMapVal.clone();
                mapOfLPTDList.add(lptMapVal);
            }
        }
        for(String lptRecId : lptMapVal.keySet()){
            if(lptRecId == 'recordId'){
                lptRecIdSet.add(String.valueOf(lptMapVal.get(lptRecId)));
            }
        }
        System.debug('first map::'+bluepaystaticMapcloned+ ':::second map:::'+mapOfLPTDList[0]);
        bluepaystaticMap.putAll(mapOfLPTDList[0]);
       
        headerValues = getColHeaderValues(bluepaystaticMap);
        
        Integer maxRows = mapOfLPTDList.size();
        for(Integer i=0; i <= maxRows; i++){
            String finalString = '';
            if(i == 0){
                finalString = getRowValues(bluepaystaticMapcloned,i);
            }else{
                finalString = getRowValues(mapOfLPTDList[i-1],i);
            
                csvRowValues.add(finalString);
            
            }
            
            
        }
        
		List<loan__Loan_Payment_Transaction__c> lptRecordsList = [SELECT Id,Name,loan__Transaction_Amount__c,Blue_Pay_Token__c,loan__Loan_Account__c,loan__Sent_to_ACH__c,loan__ACH_Filename__c FROM loan__Loan_Payment_Transaction__c WHERE Id IN: lptRecIdSet ];
        List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = 'ACH Documents' ];
        List<loan__Loan_Payment_Transaction__c> lptListToUpdate = new List<loan__Loan_Payment_Transaction__c>(); 
        loan__Loan_Payment_Transaction__c lptRecUpdate = new loan__Loan_Payment_Transaction__c();
        if(!folders.isEmpty()){
            String documentName = 'GSY-' + String.valueOf(System.today());
            String csvFile = headerValues+'\n' + String.join(csvRowValues,'\n');
            
            for(loan__Loan_Payment_Transaction__c lpt : lptRecordsList){
                lptRecUpdate.Id = lpt.Id;
                lptRecUpdate.loan__Sent_to_ACH__c = true;
                lptRecUpdate.loan__ACH_Filename__c = documentName;
                
                lptListToUpdate.add(lptRecUpdate);
            }
            
            // Insert the generated CSV file in Document object under "Setup Audit Trail Logs".
            Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType='application/vnd.ms-excel');
            SecureDML.insertRecords(doc);
            SecureDML.updateRecords(lptListToUpdate);
            
        }
    }
    
    global void finish(Database.BatchableContext BC) {       
        
        
    }
    public static String getsObjectName(Id recId){
        
        String sObjName = recId.getSObjectType().getDescribe().getName();
        
        return sObjName;
    }
    public static String getColHeaderValues(Map<String,Object> recordData){
        System.debug('record map:::'+recordData);
        String colHeader1 = '';
        String colHeader2 = '';
        String colHeader3 = '';
        String colHeader4 = '';
        String colHeader5 = '';
        String colHeader6 = '';
        String colHeader7 = '';
        
        List<String> sequentialList = new List<String>();
        for(String s: recordData.keySet()){
            sequentialList.add(s);
            System.debug('sssss::'+s);
        }
        for(String colValuesRec : sequentialList){
            if(colValuesRec == 'Terminal Id'){
                colHeader1 = colValuesRec;
            }else if(colValuesRec == 'BluePay Static'){
                colHeader2 = colValuesRec;
            }else if(colValuesRec == 'BluePay Transaction Type'){
                colHeader3 = colValuesRec;
            }else if(colValuesRec == 'BluePay Token'){
                colHeader4 = colValuesRec;
            }else if(colValuesRec == 'BluePay Static Expiry'){
                colHeader5 = colValuesRec;
            }else if(colValuesRec == 'Transaction Amount'){
                colHeader6 = colValuesRec;
            }else if(colValuesRec == 'Loan No'){
                colHeader7 = colValuesRec;
            }
        }
        
        String finalHeaderString = colHeader1 + ',' +colHeader2+ ',' +colHeader3+ ',' +colHeader4+ ',' +colHeader5+ ',' +colHeader6+ ',' +colHeader7;
        return finalHeaderString;
    }
    
    public static String getRowValues(Map<String,Object> recordData2,Integer num){
        String row1 = '';
        String row2 = '';
        String row3 = '';
        
        for(String ss : recordData2.keySet()){
            if(num == 0){
                if(ss == 'Terminal Id'){
                    bp1 = String.valueOf(recordData2.get(ss));
                }else if(ss == 'BluePay Static'){
                    bp2 = String.valueOf(recordData2.get(ss));
                }else if(ss == 'BluePay Transaction Type'){
                    bp3 = String.valueOf(recordData2.get(ss));
                }else if(ss == 'BluePay Static Expiry'){
                    bp4 = String.valueOf(recordData2.get(ss));
                }
            }else{
              
                if(ss == 'BluePay Token'){
                    row1 = String.valueOf(recordData2.get(ss));
                }else if(ss == 'Transaction Amount'){
                    row2 = String.valueOf(recordData2.get(ss));
                }else if(ss == 'Loan No'){
                    row3 = String.valueOf(recordData2.get(ss));
                }
            }
        }
        //Terminal Id,BluePay Static,BluePay Transaction Type,                     BluePay Token,         BluePay Static Expiry,      Transaction Amount,    Loan No
        String finalRowValues = bp1 + ',' + bp2 + ',' + bp3 + ',' + row1 + ',' + bp4 + ',' + row2 + ',' + row3;
        return finalRowValues;
    }
}