import { LightningElement, api } from 'lwc';

export default class DataEntryAssignBtnCell extends LightningElement {
    @api recordId;

    get isDisabled() {
        return !this.recordId;
    }

    handleAssign() {
        if (this.isDisabled) {
            return;
        }
        this.dispatchEvent(
            new CustomEvent('recordassign', {
                detail: { recordId: this.recordId },
                bubbles: true,
                composed: true
            })
        );
    }
}