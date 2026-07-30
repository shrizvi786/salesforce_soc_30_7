public with sharing class SyncStudentParentRelQueue implements Queueable, Database.AllowsCallouts {

    // FIXED: /production/
    public static String BASE_URL =
        'https://u9brxug9da.execute-api.us-east-2.amazonaws.com/producton/get-nyc-student-guardian';

    private Integer pageSize;
    private Integer chunkSize;
    private List<Integer> offsets;

    @TestVisible
    static void setBaseUrlForTest(String url) { BASE_URL = url; }

    public SyncStudentParentRelQueue(List<Integer> offsets, Integer pageSize, Integer chunkSize) {
        this.offsets   = (offsets == null) ? new List<Integer>() : new List<Integer>(offsets);
        this.pageSize  = (pageSize  == null || pageSize  <= 0) ? 1 : pageSize;
        this.chunkSize = (chunkSize == null || chunkSize <= 0) ? 3 : chunkSize;
    }

    public void execute(QueueableContext qc) {
        if (offsets.isEmpty()) return;

        Integer n = Math.min(chunkSize, offsets.size());
        List<Integer> thisChunk = new List<Integer>();
        for (Integer i = 0; i < n; i++) thisChunk.add(offsets[i]);

        List<Integer> remaining = new List<Integer>();
        for (Integer j = n; j < offsets.size(); j++) remaining.add(offsets[j]);

        Map<String, Student_Parent_Relationship__c> globalMap = new Map<String, Student_Parent_Relationship__c>();

        for (Integer off : thisChunk) {
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(BASE_URL + '?limit=' + pageSize + '&offset=' + off);
                req.setMethod('GET');
                HttpResponse res = new Http().send(req);
                if (res.getStatusCode() != 200) continue;

                Map<String,Object> wrap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> rows = (List<Object>) wrap.get('body');
                if (rows == null || rows.isEmpty()) continue;

                Set<String> studExt = new Set<String>();
                Set<String> gardExt = new Set<String>();
                for (Object o : rows) {
                    Map<String,Object> m = (Map<String,Object>) o;
                    String sExt = (String)m.get('Student__c');
                    String gExt = (String)m.get('Student_Parent_Guardian__c');
                    if (sExt != null) studExt.add(sExt);
                    if (gExt != null) gardExt.add(gExt.replaceAll('_',''));
                }

                Map<String,Id> studMap = new Map<String,Id>();
                if (!studExt.isEmpty()) {
                    for (Student__c s : [
                        SELECT Id, Student_ID__c
                        FROM Student__c
                        WHERE Student_ID__c IN :studExt
                    ]) studMap.put(s.Student_ID__c, s.Id);
                }

                Map<String,Id> gardMap = new Map<String,Id>();
                if (!gardExt.isEmpty()) {
                    for (Student_Parent_Guardian__c g : [
                        SELECT Id, phone_guardian__c
                        FROM Student_Parent_Guardian__c
                        WHERE phone_guardian__c IN :gardExt
                    ]) gardMap.put(g.phone_guardian__c, g.Id);
                }

                for (Object o : rows) {
                    Map<String,Object> m = (Map<String,Object>) o;
                    String rawSid = (String)m.get('Student__c');
                    String rawGid = (String)m.get('Student_Parent_Guardian__c');
                    if (rawGid != null) rawGid = rawGid.replaceAll('_','');

                    Id sId = (rawSid == null) ? null : studMap.get(rawSid);
                    Id gId = (rawGid == null) ? null : gardMap.get(rawGid);
                    if (sId == null || gId == null) continue;

                    String relKey = sId + '_' + gId;
                    if (!globalMap.containsKey(relKey)) {
                        globalMap.put(relKey, new Student_Parent_Relationship__c(
                            Student__c                 = sId,
                            Student_Parent_Guardian__c = gId,
                            Relationship_Key__c        = relKey
                        ));
                    }
                }

            } catch (Exception ex) {
                System.debug('Error at offset ' + off + ': ' + ex.getMessage());
            }
        }

        if (!globalMap.isEmpty()) {
            List<Student_Parent_Relationship__c> allToUpsert = globalMap.values();
            Integer total = allToUpsert.size();

            SyncGate.bypassSFSync = true;
            try {
                Integer idx = 0;
                while (idx < total) {
                    Integer endIdx = Math.min(idx + 10000, total);
                    List<Student_Parent_Relationship__c> slice = new List<Student_Parent_Relationship__c>();
                    for (Integer k = idx; k < endIdx; k++) slice.add(allToUpsert[k]);
                    upsert slice Relationship_Key__c;
                    idx = endIdx;
                }
            } finally {
                SyncGate.bypassSFSync = false;
            }
        }

        if (!remaining.isEmpty()) {
            System.enqueueJob(new SyncStudentParentRelQueue(remaining, pageSize, chunkSize));
        }
    }

    public static Id kickoff(Integer pageSize, Integer chunkSize) {
        Integer totalCount = 0;
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(BASE_URL + '?limit=1&offset=0');
            req.setMethod('GET');
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200) {
                Map<String,Object> wrap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                Object tc = wrap.get('totalCount');
                if (tc instanceof Decimal) totalCount = ((Decimal)tc).intValue();
                else if (tc instanceof Integer) totalCount = (Integer) tc;
            }
        } catch (Exception e) {
            System.debug('kickoff probe failed: ' + e.getMessage());
        }
        if (totalCount <= 0) return null;

        Integer ps = (pageSize == null || pageSize <= 0) ? 1 : pageSize;
        List<Integer> offs = new List<Integer>();
        for (Integer off = 0; off < totalCount; off += ps) offs.add(off);

        Integer cs = (chunkSize == null || chunkSize <= 0) ? 3 : chunkSize;
        return System.enqueueJob(new SyncStudentParentRelQueue(offs, ps, cs));
    }
}