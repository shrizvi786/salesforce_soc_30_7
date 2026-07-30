/**
 * Self-rescheduling job: toggles update_monday_board__c ONE Account/DBN at a time.
 * CHUNK_SIZE=1 so MondayOpportunitySync does not hit Too many callouts.
 *
 * Start (live):
 *   Datetime runAt = Datetime.now().addSeconds(10);
 *   String cron = runAt.format('ss mm HH dd MM ? yyyy');
 *   System.schedule('ToggleMondayBoard_Live', cron, new ToggleMondayBoardPerDbnSched(false, null));
 */
public class ToggleMondayBoardPerDbnSched implements Schedulable {

    private final Boolean dryRun;
    private final Id afterAccountId;

    public ToggleMondayBoardPerDbnSched() {
        this(false, null);
    }

    public ToggleMondayBoardPerDbnSched(Boolean dryRun, Id afterAccountId) {
        this.dryRun = dryRun == true;
        this.afterAccountId = afterAccountId;
    }

    public void execute(SchedulableContext sc) {
        ToggleMondayBoardPerDbnService.Result result =
            ToggleMondayBoardPerDbnService.runNextChunk(dryRun, afterAccountId);

        if (result.mediaOnlyDbns != null && !result.mediaOnlyDbns.isEmpty()) {
            System.debug('Chunk media-only DBNs: ' + String.join(result.mediaOnlyDbns, ', '));
        }

        if (result.done != true && result.lastAccountId != null) {
            // 1 Opp/Account per run — give MondayOpportunitySync time to finish callouts
            Datetime runAt = Datetime.now().addMinutes(1);
            String jobName = 'ToggleMondayBoard_' + String.valueOf(runAt.getTime());
            String cron = runAt.format('ss mm HH dd MM ? yyyy');
            System.schedule(
                jobName,
                cron,
                new ToggleMondayBoardPerDbnSched(dryRun, result.lastAccountId)
            );
            System.debug('Rescheduled next DBN at ' + runAt + ' afterAccountId=' + result.lastAccountId);
        } else {
            System.debug('ToggleMondayBoardPerDbnSched COMPLETE. toggled=' + result.toggledCount);
        }
    }
}