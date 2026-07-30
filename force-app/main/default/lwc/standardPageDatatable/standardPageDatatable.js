import LightningDatatable from 'lightning/datatable';
import standardHideToggleTemplate from './standardHideToggleType.html';
import standardProficiencyTemplate from './standardProficiencyType.html';

export default class StandardPageDatatable extends LightningDatatable {
    static customTypes = {
        standardHideToggle: {
            template: standardHideToggleTemplate,
            standardCellLayout: true,
            typeAttributes: ['sectionId', 'boolVal']
        },
        standardProficiency: {
            template: standardProficiencyTemplate,
            standardCellLayout: true,
            typeAttributes: ['sectionId']
        }
    };
}