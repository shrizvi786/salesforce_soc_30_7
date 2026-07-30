import { LightningElement, api } from 'lwc';

export default class HmhPerfBandCell extends LightningElement {
    @api settingId;

    handleEdit() {
        this.dispatchEvent(
            new CustomEvent('bandedit', {
                detail: { settingId: this.settingId },
                bubbles: true,
                composed: true
            })
        );
    }
}