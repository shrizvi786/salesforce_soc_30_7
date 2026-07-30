import { LightningElement, api } from 'lwc';

export default class HmhAssignBtnCell extends LightningElement {
    @api settingId;

    handleAssign() {
        this.dispatchEvent(
            new CustomEvent('bandassign', {
                detail: { settingId: this.settingId },
                bubbles: true,
                composed: true
            })
        );
    }
}