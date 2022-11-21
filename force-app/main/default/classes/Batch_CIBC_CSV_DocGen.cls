/*********************************************************************************************************************************************************************************************************************************
* Name    : Batch_CIBC_CSV_DocGen
* Company : GoEasy
* Purpose : Batch job to generate CIBC CSV Files
* Author  : Shubham Shukla
* *****************************************************************************************************************************************************************************************************************************/
global class Batch_CIBC_CSV_DocGen implements Database.Batchable<sObject>,Database.Stateful{
    global String query = '';
    global Static String headerValues = '';
    global List<String> csvRowValues = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        query = 'SELECT Id,Name FROM  Account LIMIT 10';
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Account> scope) {
    
        String res = CLS_CIBC_DocGenCallout.generateCibcFile();
        System.debug('#$$$$$$$$$$$$$$$$$###'+res);
       
        Map<String, Object> meta = (Map<String, Object>)JSON.deserializeUntyped(res);
        meta.remove('GlobalParams');
        String apcRowString = '';
        String cibcstaticRowString = '';
        Map<String, Object> loanAPC = new Map<String, Object>();
        Map<String, Object> cibcStatiucMap = new Map<String, Object>();
        List<Map<String, Object>> mapOfLDTList = new List<Map<String, Object>>();
        List<Map<String, Object>> mapOfOTDList = new List<Map<String, Object>>();
        for(String csvColHeader : meta.keySet()){
            if(getsObjectName(csvColHeader) == 'loan__Automated_Payment_Configuration__c'){
                String apcrec = JSON.serialize(meta.get(csvColHeader));
                loanAPC = (Map<String, Object>)JSON.deserializeUntyped(apcrec);
            }else if(getsObjectName(csvColHeader) == 'loan__Loan_Disbursal_Transaction__c'){  
                String LDTRec = JSON.serialize(meta.get(csvColHeader));
                Map<String, Object> ldtMapVal = (Map<String, Object>)JSON.deserializeUntyped(LDTRec);
                mapOfLDTList.add(ldtMapVal);
            }else if(getsObjectName(csvColHeader) == 'loan__Borrower_Refund_Transaction__c'){
                String OTDRec = JSON.serialize(meta.get(csvColHeader));
                Map<String, Object> otdMapVal = (Map<String, Object>)JSON.deserializeUntyped(OTDRec);
                mapOfOTDList.add(otdMapVal);
            }else if(getsObjectName(csvColHeader) == 'CIBC_Static_Mappings__c'){
                String cibcstaticRec = JSON.serialize(meta.get(csvColHeader));
                cibcStatiucMap = (Map<String, Object>)JSON.deserializeUntyped(cibcstaticRec);
            }
            
        }   
        
		
        headerValues += getColHeaderValues(loanAPC);
        if(!mapOfLDTList.isEmpty()){
            headerValues += getColHeaderValues(mapOfLDTList[0]);
        }
        if(!mapOfOTDList.isEmpty()){
            headerValues += getColHeaderValues(mapOfOTDList[0]);
        }
        headerValues += getColHeaderValues(cibcStatiucMap) + 'NbOfTxs';
      
        for(Object apcValRecs : loanAPC.values()){
            apcRowString +=  apcValRecs +',';
        }
        for(Object cibcValRecs : cibcStatiucMap.values()){
            cibcstaticRowString += cibcValRecs +',';
        }
        Integer maxRows = mapOfLDTList.size()>mapOfOTDList.size()?mapOfLDTList.size():mapOfOTDList.size();
        
        for(integer i=0;i<maxRows;i++){
            String singleRow = apcRowString;
            if(i < mapOfLDTList.size()){
                for(Object ldt : mapOfLDTList[i].values()){
                    singleRow += ldt +',';
                    
                }
            }else{
                for(Object ldt : mapOfLDTList[0].values()){
                    singleRow += ''+',';
                    
                }
            }
            if(i < mapOfOTDList.size()){
                 for(Object odt : mapOfOTDList[i].values()){
                    singleRow += odt +',';
                }
            }else{
                if(!mapOfOTDList.isEmpty()){
                    for(Object odt : mapOfOTDList[0].values()){
                        singleRow += '' +',';
                    }
                }
            }
            singleRow +=  cibcstaticRowString;
            singleRow += maxRows;
            System.debug('single rows::'+singleRow);
            csvRowValues.add(singleRow);
        }
      System.debug('$$$$:::'+csvRowValues);
        List<Folder> folders = [SELECT Id, Name FROM Folder WHERE Name = 'ACH Documents' ];
        if(!folders.isEmpty()){
            String documentName = 'CIBC'+ 'Pain001v03'+'Tests';
           
            String csvFile = headerValues+'\n' + String.join(csvRowValues,'\n');
            
            // Insert the generated CSV file in Document object under "Setup Audit Trail Logs".
            Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType='application/vnd.ms-excel');
            SecureDML.insertRecords(doc);
        }
    }
    
    global void finish(Database.BatchableContext BC) {       
        
      
    }
    
    public static String getsObjectName(Id recId){
        
        String sObjName = recId.getSObjectType().getDescribe().getName();
        
        return sObjName;
    }
    public static String getColHeaderValues(Map<String,Object> recordData){
        String colHeader = '';
        for(String s: recordData.keySet()){
            System.debug('@@###::'+s);
                colHeader += s +',';
            
        }
        return colHeader;
    }
}