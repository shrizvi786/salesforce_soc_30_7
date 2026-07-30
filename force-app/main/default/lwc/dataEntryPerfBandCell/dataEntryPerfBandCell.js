import { LightningElement, api } from 'lwc';

export default class DataEntryPerfBandCell extends LightningElement {
    @api recordId;

    get isEditDisabled() {
        return !this.recordId;
    }

    handleEdit() {
        if (this.isEditDisabled) {
            return;
        }
        this.dispatchEvent(
            new CustomEvent('recordedit', {
                detail: { recordId: this.recordId },
                bubbles: true,
                composed: true
            })
        );
    }
}