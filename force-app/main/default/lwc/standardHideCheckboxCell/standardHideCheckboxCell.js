import { LightningElement, api } from 'lwc';

export default class StandardHideCheckboxCell extends LightningElement {
    @api sectionId;
    @api checked;

    get isDisabled() {
        return !this.sectionId;
    }

    handleChange(event) {
        if (this.isDisabled) {
            return;
        }
        this.dispatchEvent(
            new CustomEvent('sectionhidechange', {
                detail: {
                    sectionId: this.sectionId,
                    value: event.detail.checked
                },
                bubbles: true,
                composed: true
            })
        );
    }
}