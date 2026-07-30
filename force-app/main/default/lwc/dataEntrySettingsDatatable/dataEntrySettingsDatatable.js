import LightningDatatable from 'lightning/datatable';
import dataEntryPerfBandTemplate from './dataEntryPerfBandType.html';
import dataEntryAssignBtnTemplate from './dataEntryAssignBtnType.html';
import dataEntryDeleteBtnTemplate from './dataEntryDeleteBtnType.html';
import dataEntryBoolToggleTemplate from './dataEntryBoolToggleType.html';

export default class DataEntrySettingsDatatable extends LightningDatatable {
    static customTypes = {
        dataEntryPerfBand: {
            template: dataEntryPerfBandTemplate,
            standardCellLayout: true,
            typeAttributes: ['recordId']
        },
        dataEntryAssignBtn: {
            template: dataEntryAssignBtnTemplate,
            standardCellLayout: true,
            typeAttributes: ['recordId']
        },
        dataEntryDeleteBtn: {
            template: dataEntryDeleteBtnTemplate,
            standardCellLayout: true,
            typeAttributes: ['recordId']
        },
        dataEntryBoolToggle: {
            template: dataEntryBoolToggleTemplate,
            standardCellLayout: true,
            typeAttributes: ['recordId', 'boolVal', 'mode']
        }
    };
}