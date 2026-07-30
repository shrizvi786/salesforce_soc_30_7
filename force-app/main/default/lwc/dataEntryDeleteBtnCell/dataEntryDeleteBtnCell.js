import { LightningElement, api } from 'lwc';

export default class DataEntryDeleteBtnCell extends LightningElement {
    @api recordId;

    get isDisabled() {
        return !this.recordId;
    }

    handleDelete() {
        if (this.isDisabled) {
            return;
        }
        this.dispatchEvent(
            new CustomEvent('recorddelete', {
                detail: { recordId: this.recordId },
                bubbles: true,
                composed: true
            })
        );
    }
}