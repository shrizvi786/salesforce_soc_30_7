import { LightningElement, api } from 'lwc';

export default class HmhInlineCheckboxCell extends LightningElement {
    @api settingId;
    @api checked;
    /** 'hide' | 'delete' */
    @api mode;

    get ariaLabel() {
        return this.mode === 'delete' ? 'Delete this setting' : 'Hide from dashboard';
    }

    handleChange(event) {
        const val = event.detail.checked;
        this._emitToggle(val);
    }

    _emitToggle(value) {
        if (this.mode === 'delete' && value !== true) {
            return;
        }
        this.dispatchEvent(
            new CustomEvent('settingtoggle', {
                detail: {
                    settingId: this.settingId,
                    mode: this.mode,
                    value
                },
                bubbles: true,
                composed: true
            })
        );
    }
}