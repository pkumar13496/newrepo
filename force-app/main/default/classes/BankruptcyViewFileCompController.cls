public class BankruptcyViewFileCompController {
    
    @AuraEnabled 
    
    public static List<ContentDocument> getFiles(String recordId){ 
        System.debug('RecordId - '+recordId);
        Set<Id> recordIds = new Set<Id>{recordId};
        
        List<ContentDocumentLink> cdlList = [SELECT Id, LinkedEntityId, ContentDocumentId FROM 
                                             ContentDocumentLink WHERE LinkedEntityId IN :recordIds 
                                            ];                         
        Set<Id> documentIds = new Set<Id>(); 
        for(ContentDocumentLink cdl:cdlList){  
            documentIds.add(cdl.ContentDocumentId);  
        }    
        return [SELECT Id, Title, FileType FROM ContentDocument WHERE Id IN :documentIds];        
    } 

}