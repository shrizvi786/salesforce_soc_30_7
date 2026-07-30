public class DeletePayRollRecord  {
    public static void deletePayRoll() {     
        // Query and delete records created on the 15th
        List<Payroll__c> recordsToDelete = [
            SELECT Id
            FROM Payroll__c
            WHERE Employee_Work_Email__c NOT IN (
'amaury.ramirez@solvedconsulting.com',
'evelyn.rebollar@solvedconsulting.com',
'allison.arthurmay@solvedconsulting.com',
'joshua.taton@solvedconsulting.com',
'tiayana.marks@solvedconsulting.com',
'geillan.aly@solvedconsulting.com',
'mandy.vadnai@solvedconsulting.com',
'latoya.massey@solvedconsulting.com',
'lynne@solvedconsulting.com',
'martin.reed@solvedconsulting.com',
'najawa.giddings@solvedconsulting.com',

                'albert.barabas@solvedconsulting.com',
                'angela.reynolds@solvedconsulting.com',
                'bianca.tejada@solvedconsulting.com',
                'caroline.hopenwasser@solvedconsulting.com',
                'carrie.kizuka@solvedconsulting.com',
                'catlin.tucker@solvedconsulting.com',
                'christine.delnegro@solvedconsulting.com',
                'christine.delnegro@solvedconsulting.com',
                'denise.savoy@solvedconsulting.com',
                'elisa.tejada@solvedconsulting.com',
                'frances.levine@solvedconsulting.com',
                'halle.kananack@solvedconsulting.com',
                'hannah.dato@solvedconsulting.com',
                'harriette.grosvenor@solvedconsulting.com',
                'helene.alalouf@solvedconsulting.com',
                'julio.penagos@solvedconsulting.com',
                'martin.gottlieb@solvedconsulting.com',
                'martin.wilson@solvedconsulting.com',
                'mary.danke@solvedconsulting.com',
                'maura.musso@solvedconsulting.com',
                'trish.walter@solvedconsulting.com',
                'risa.katz@solvedconsulting.com',
                'ronald.morris@solvedconsulting.com',
                'suzanne.brooks@solvedconsulting.com',
                'susan.midlarsky@solvedconsulting.com',
                'victoria.seawall@solvedconsulting.com',
                'wayne.edwards@solvedconsulting.com',
                'victoria.seawall@solvedconsulting.com',
                'christine.delnegro@solvedconsulting.com',
                'hannah.dato@solvedconsulting.com',
                'christine.delnegro@solvedconsulting.com',
                'ria.grosvenor@solvedconsulting.com',
                'risa.katz@solvedconsulting.com',
                'christine.delnegro@solvedconsulting.com',
                'damian.butler@solvedconsulting.com',
                'christine.delnegro@solvedconsulting.com',
                'wayne.edwards@solvedconsulting.com',
                'mary.ferretti@solvedconsulting.com',
                'risa.katz@solvedconsulting.com',
                'susan.midlarsky@solvedconsulting.com',
                'julio.penagos@solvedconsulting.com',
                'krishna.saha@solvedconsulting.com',
                'denise.savoy@solvedconsulting.com',
                'marcy.sutherland@solvedconsulting.com',
                'martin.wilson@solvedconsulting.com',
                'wayne.edwards@solvedconsulting.com',
                'kamal.james@solvedconsulting.com',
                'nadelyn.pichardo@solvedconsulting.com',
                'helene.alalouf@solvedconsulting.com',
                'hannah.dato@solvedconsulting.com',
                'mary.ferretti@solvedconsulting.com',
                'risa.katz@solvedconsulting.com',
                'Beverley.Gallimore@solvedconsulting.com',
                'christina.wallace@solvedconsulting.com',
                'Damian.butler@solvedconsulting.com',
                'Evelyn.Rebollar@solvedconsulting.com',
                'John.Schembari@solvedconsulting.com',
                'Eileen.Murray@solvedconsulting.com',
                'Krishna.Saha@solvedconsulting.com',
                'Linda.Fusco@solvedconsulting.com',
                'Marcy.Sutherland@solvedconsulting.com',
                'Martin.Reed@solvedconsulting.com',
                'Christina.koza@solvedconsulting.com',
                'Deon.Edwards@solvedconsulting.com',
                'Geillan.Aly@solvedconsulting.com'
            )
        ];
        system.debug('recordsToDelete ' +recordsToDelete);
        // Delete the records
        delete recordsToDelete;
        
        
    }
}