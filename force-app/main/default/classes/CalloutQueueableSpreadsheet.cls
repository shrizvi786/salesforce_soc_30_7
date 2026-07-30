public class CalloutQueueableSpreadsheet implements Queueable {
    public void execute(QueueableContext context) {
      //  SpreadsheetData spreadsheetData = new SpreadsheetData();
      //  spreadsheetData.fetchAndProcessAPIdata();
        SpreadsheetData.fetchAndProcessAPIdata();
    }
}