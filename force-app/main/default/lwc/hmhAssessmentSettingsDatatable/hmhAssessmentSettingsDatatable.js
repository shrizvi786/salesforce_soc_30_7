import LightningDatatable from 'lightning/datatable';
import hmhPerfBandTemplate from './hmhPerfBandType.html';
import hmhAssignBtnTemplate from './hmhAssignBtnType.html';
import hmhBoolToggleTemplate from './hmhBoolToggleType.html';

export default class HmhAssessmentSettingsDatatable extends LightningDatatable {
    static customTypes = {
        hmhPerfBand: {
            template: hmhPerfBandTemplate,
            standardCellLayout: true,
            typeAttributes: ['settingId']
        },
        hmhAssignBtn: {
            template: hmhAssignBtnTemplate,
            standardCellLayout: true,
            typeAttributes: ['settingId']
        },
        hmhBoolToggle: {
            template: hmhBoolToggleTemplate,
            standardCellLayout: true,
            typeAttributes: ['settingId', 'boolVal', 'mode']
        }
    };
}