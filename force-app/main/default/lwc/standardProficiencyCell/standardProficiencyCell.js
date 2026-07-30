import { LightningElement, api } from 'lwc';

export default class StandardProficiencyCell extends LightningElement {
    @api sectionId;

    get isDisabled() {
        return !this.sectionId;
    }

    handleEditEla() {
        this._emitEdit('ELA');
    }

    handleEditMath() {
        this._emitEdit('MATH');
    }

    _emitEdit(subjectKey) {
        if (this.isDisabled) {
            return;
        }
        this.dispatchEvent(
            new CustomEvent('proficiencyedit', {
                detail: {
                    sectionId: this.sectionId,
                    subjectKey
                },
                bubbles: true,
                composed: true
            })
        );
    }
}