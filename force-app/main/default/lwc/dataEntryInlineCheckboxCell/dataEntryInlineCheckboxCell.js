import { LightningElement, api } from 'lwc';

export default class DataEntryInlineCheckboxCell extends LightningElement {
    @api recordId;
    @api checked;
    @api mode;

    get isDisabled() {
        return !this.recordId;
    }

    get ariaLabel() {
        return 'Hide from dashboard';
    }

    handleChange(event) {
        if (this.isDisabled) {
            return;
        }
        this._emitToggle(event.detail.checked);
    }

    _emitToggle(value) {
        this.dispatchEvent(
            new CustomEvent('recordtoggle', {
                detail: {
                    recordId: this.recordId,
                    mode: this.mode,
                    value
                },
                bubbles: true,
                composed: true
            })
        );
    }
}