public class convertJSONToCSV {
    public static String doAreaCallout(String s,boolean isTestCase, String apiKey) {
        
        system.debug('inside convertJSONToCSV, doAreaCalloutMethod');
        s = isTestCase==true ? '[{"Title__c": "Test","Like__c": "1","Thanks__c": "0","Helpful__c": "0","Share__c": "0","Notification_Id__c": "1"}]' : s;
        system.debug('In convertJSONToCSV class '+isTestCase);
        s = isTestCase==false ? s.remove('{"records":') : s;
        s = isTestCase==false ? s.replace(']}', ']') : s;
        //System.debug('Data: ' +s);
        
        List<Object> entryList = (List<Object>) JSON.deserializeUntyped(s);
        System.debug('entryList: '+entryList);
        
        List<Map<String, Object>> mapList = new List<Map<String, Object>>();
        Set<String> keySet = new Set<String>();  
        
        for(Object entry : entryList) {
            Map<String, Object> m = (Map<String, Object>)(entry);
            keySet.addAll(m.keySet());
            mapList.add(m);
        }
        
        List<String> keys = new List<String>(keySet);
        keys.sort();
        //System.debug(keys);
        
        List<List<String>> csvLines = new List<List<String>>();
        
        for (Integer i = 0; i <= mapList.size(); i++) {
            csvLines.add(new List<String>());
        }       
        
        for (String key : keys) {
            csvLines.get(0).add('"' + key + '"');        
            for (Integer i = 1; i <= mapList.size(); i++) {
                String tmp = String.valueOf(mapList.get(i - 1).get(key));
                
                if(apiKey!='gradedPlusActivity' && apiKey!='Students' && apiKey!='Account' && apiKey!='Student_Parent_Relationship__c'){                    
                    //system.debug('Inside escape characters');
                    tmp = mapList.get(i - 1).get(key) != null ? tmp.escapeHtml4():tmp;
                    tmp = mapList.get(i - 1).get(key) != null ? tmp.replaceAll('[^a-zA-Z0-9\\s+]',''):tmp;            
                    tmp = mapList.get(i - 1).get(key) != null ? tmp.replaceAll('"','') : tmp;
                    tmp = mapList.get(i - 1).get(key) != null ? tmp.replaceAll('[^\\w\\s]','') : tmp;
                    tmp = mapList.get(i - 1).get(key) != null ? tmp.replaceAll('[^\\p{L}\\p{M}\\p{N}\\p{P}\\p{Z}\\p{Cf}\\p{Cs}\\s]','') : tmp;    
                }
                
                /*if(key == 'Grade__c'){
if(tmp != '0K'){
tmp = mapList.get(i - 1).get(key) != null ? tmp.replaceFirst('^0+', '') : tmp;
//System.debug('tmp' + tmp);
}
}*/
                
                if(tmp == null || tmp == 'null' || String.isBlank(tmp)) {
                    csvLines.get(i).add('"#N/A"'); //this is to override the SF existing value with null/empty in case of null or empty string exist in the API
                } else {
                    csvLines.get(i).add('"' + tmp + '"');
                }
                
                
                /*if((String)(String.valueOf(tmp))==null){                    
csvLines.get(i).add('""');     
}else{
csvLines.get(i).add('"' + (String)(String.valueOf(tmp)) + '"');   
}*/
            }
        }   
        
        String csvFile = '';
        for (List<String> csvLine : csvLines) {
            String line = '';
            for (Integer i = 0; i < csvLine.size() - 1; i++) {
                line += csvLine.get(i) + ',';
            }
            line += csvLine.get(csvLine.size() - 1);
            
            //system.debug('replaced Line: '+line);
            csvFile += line + '\n';
            //system.debug('Line: '+line);         
        }
        //System.debug(csvFile);    
        return csvFile;
    }
}