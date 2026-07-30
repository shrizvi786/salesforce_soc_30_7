import LightningDatatable from 'lightning/datatable';
import nysHideToggleTemplate from './nysHideToggleType.html';

export default class NysExamsDatatable extends LightningDatatable {
    static customTypes = {
        nysHideToggle: {
            template: nysHideToggleTemplate,
            standardCellLayout: true,
            typeAttributes: ['sectionId', 'boolVal']
        }
    };
}