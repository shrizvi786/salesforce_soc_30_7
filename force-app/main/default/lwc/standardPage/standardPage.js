import { LightningElement, wire, track } from 'lwc';
import getRows from '@salesforce/apex/StandardPageController.getRows';
import updateHide from '@salesforce/apex/StandardPageController.updateHide';
import getPerformanceBands from '@salesforce/apex/StandardPageController.getPerformanceBands';
import savePerformanceBands from '@salesforce/apex/StandardPageController.savePerformanceBands';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const LEVEL_DEFAULTS = [
    { key: '1', num: 1, defaultName: 'Below Level', defaultColor: '#E24B4A', defaultValue: 65 },
    { key: '2', num: 2, defaultName: 'On Level', defaultColor: '#EF9F27', defaultValue: 65 },
    { key: '3', num: 3, defaultName: 'Above Level', defaultColor: '#639922', defaultValue: 80 },
    { key: '4', num: 4, defaultName: 'Level 4', defaultColor: '#378add', defaultValue: 85 }
];

const LEVEL5_DEFAULT = {
    key: '5',
    num: 5,
    defaultName: 'Level 5',
    defaultColor: '#378add',
    defaultValue: null
};

const COLOR_PALETTES = {
    3: ['#E24B4A', '#EF9F27', '#639922'],
    4: ['#E24B4A', '#EF9F27', '#639922', '#378add'],
    5: ['#E24B4A', '#E89A2E', '#EF9F27', '#639922', '#378add']
};

const DTO_THRESH_KEYS = {
    '1': 'level1Below',
    '2': 'level2Min',
    '3': 'level3Min',
    '4': 'level4Min',
    '5': 'level5Min'
};
const DTO_COLOR_KEYS = {
    '1': 'level1Color',
    '2': 'level2Color',
    '3': 'level3Color',
    '4': 'level4Color',
    '5': 'level5Color'
};
const DTO_NAME_KEYS = {
    '1': 'level1Name',
    '2': 'level2Name',
    '3': 'level3Name',
    '4': 'level4Name',
    '5': 'level5Name'
};

function hexToRgba(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

const TABLE_COLUMNS = [
    {
        label: 'Name',
        fieldName: 'nameUrl',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: { fieldName: 'name' },
            target: '_self'
        }
    },
    { label: 'DBN', fieldName: 'dbn', type: 'text', sortable: true },
    {
        label: 'Proficiency Score',
        type: 'standardProficiency',
        sortable: false,
        initialWidth: 220,
        typeAttributes: {
            sectionId: { fieldName: 'sectionId' }
        }
    },
    {
        label: 'Hide',
        fieldName: 'hide',
        type: 'standardHideToggle',
        sortable: true,
        initialWidth: 84,
        typeAttributes: {
            sectionId: { fieldName: 'sectionId' },
            boolVal: { fieldName: 'hide' }
        }
    }
];

export default class StandardPage extends LightningElement {
    columns = TABLE_COLUMNS;

    @track datatableRenderKey = 0;
    allRows = [];
    rows = [];
    searchTerm = '';
    wiredRowsResult;
    isLoadingRows = true;
    sortedBy = 'name';
    sortDirection = 'asc';

    isBandsModalOpen = false;
    isBandsLoading = false;
    isSavingBands = false;
    selectedBandsRow = null;
    selectedSubjectKey = '';
    editingLevelKey = null;
    @track levels = [];

    @wire(getRows)
    wiredRows(result) {
        this.wiredRowsResult = result;
        if (result.data) {
            this.allRows = this.mapRows(result.data);
            this.applyFiltersAndSort();
            this.isLoadingRows = false;
        } else if (result.error) {
            this.isLoadingRows = false;
        }
    }

    get hasRows() {
        return this.rows && this.rows.length > 0;
    }

    get hasAnyRows() {
        return this.allRows && this.allRows.length > 0;
    }

    get isSearchActive() {
        return !!(this.searchTerm || '').trim();
    }

    get showingRange() {
        if (!this.hasAnyRows) {
            return '';
        }
        const total = this.allRows.length;
        const visible = this.rows.length;
        if (this.isSearchActive) {
            return `Showing ${visible} of ${total} section record(s)`;
        }
        return `${total} Comprehensive Standard section record(s)`;
    }

    get datatableSortedBy() {
        return this.sortedBy === 'name' ? 'nameUrl' : this.sortedBy;
    }

    get bandsModalTitle() {
        if (!this.selectedBandsRow) {
            return 'Proficiency score';
        }
        const subject = this.selectedSubjectKey === 'MATH' ? 'Math' : 'ELA';
        return `Proficiency score — ${subject} — ${this.selectedBandsRow.name}`;
    }

    get hasLevel4() {
        return this.levels.some((l) => l.key === '4');
    }

    get hasLevel5() {
        return this.levels.some((l) => l.key === '5');
    }

    get canAddLevel() {
        return !this.hasLevel5;
    }

    get addLevelLabel() {
        return this.hasLevel5 ? '' : 'Add Level 5';
    }

    get levelsWithStyles() {
        const lastKey = this.levels.length > 0 ? this.levels[this.levels.length - 1].key : null;
        return this.levels.map((l) => {
            const c = l.color || '#cccccc';
            let inputLabel;
            if (l.key === '1') {
                inputLabel = 'Below:';
            } else if (l.key === lastKey) {
                inputLabel = 'Above:';
            } else {
                inputLabel = 'Min:';
            }
            return {
                ...l,
                cardStyle: `background-color: ${hexToRgba(c, 0.12)}; border-left: 4px solid ${c};`,
                badgeStyle: `background-color: ${c}; color: #fff;`,
                inputLabel,
                canRemove: l.key === '5',
                isEditing: l.key === this.editingLevelKey
            };
        });
    }

    get sequentialError() {
        for (let i = 1; i < this.levels.length; i++) {
            const prev = this.levels[i - 1].value;
            const curr = this.levels[i].value;
            if (prev != null && curr != null && curr < prev) {
                return 'Each level\'s value must be greater than or equal to the previous level.';
            }
        }
        return '';
    }

    get hasSequentialError() {
        return this.sequentialError !== '';
    }

    get isBandsSaveDisabled() {
        return this.isSavingBands || this.hasSequentialError;
    }

    mapRows(data) {
        return (data || []).map((row) => ({
            ...row,
            nameUrl: row.sectionId
                ? `/lightning/r/Dashboard_Section__c/${row.sectionId}/view`
                : null
        }));
    }

    applyFiltersAndSort() {
        let filtered = this.allRows;
        const term = (this.searchTerm || '').trim().toLowerCase();
        if (term) {
            filtered = filtered.filter((row) => (row.dbn || '').toLowerCase().includes(term));
        }
        this.rows = this.sortData(this.sortedBy, this.sortDirection, [...filtered]);
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.applyFiltersAndSort();
        this.datatableRenderKey += 1;
    }

    handleSort(event) {
        let { fieldName, sortDirection } = event.detail;
        if (fieldName === 'nameUrl') {
            fieldName = 'name';
        }
        this.sortedBy = fieldName;
        this.sortDirection = sortDirection;
        this.applyFiltersAndSort();
    }

    async handleSectionHideChange(event) {
        const { sectionId, value } = event.detail || {};
        if (!sectionId) {
            return;
        }

        try {
            await updateHide({ sectionId, hideVal: value });
            this.showToast('Saved', 'Hide updated.', 'success');
            await this.refreshRows();
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
            this.datatableRenderKey += 1;
        }
    }

    async handleProficiencyEdit(event) {
        const { sectionId, subjectKey } = event.detail || {};
        if (!sectionId || !subjectKey) {
            return;
        }
        const row = (this.allRows || []).find((r) => r.sectionId === sectionId);
        if (!row) {
            return;
        }
        await this.openBandsModal(row, subjectKey);
    }

    async openBandsModal(row, subjectKey) {
        this.selectedBandsRow = row;
        this.selectedSubjectKey = subjectKey;
        this.isBandsModalOpen = true;
        this.isBandsLoading = true;
        this.editingLevelKey = null;
        this.levels = LEVEL_DEFAULTS.map((d) => ({
            ...d,
            value: d.defaultValue,
            color: d.defaultColor,
            levelName: d.defaultName
        }));

        try {
            const dto = await getPerformanceBands({
                sectionId: row.sectionId,
                subjectKey
            });
            const merged = this._mergeLevelsFromDto(dto);
            if (merged) {
                this.levels = merged;
            }
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        }
        this.isBandsLoading = false;
    }

    closeBandsModal() {
        this.isBandsModalOpen = false;
        this.selectedBandsRow = null;
        this.selectedSubjectKey = '';
        this.levels = [];
        this.editingLevelKey = null;
        this.isSavingBands = false;
    }

    handleAddLevel() {
        if (this.hasLevel5) {
            return;
        }
        this.levels = [
            ...this.levels,
            {
                ...LEVEL5_DEFAULT,
                value: LEVEL5_DEFAULT.defaultValue,
                color: LEVEL5_DEFAULT.defaultColor,
                levelName: LEVEL5_DEFAULT.defaultName
            }
        ].sort((a, b) => a.num - b.num);
        this._applyColorPalette();
    }

    handleRemoveLevel(event) {
        const key = event.currentTarget.dataset.level;
        this.levels = this.levels.filter((l) => l.key !== key);
        this._applyColorPalette();
    }

    handleBadgeClick(event) {
        const key = event.currentTarget.dataset.level;
        if (key === '5') {
            this.levels = this.levels.filter((l) => l.key !== key);
            this._applyColorPalette();
        }
    }

    handleLabelDblClick(event) {
        const key = event.currentTarget.dataset.level;
        this.editingLevelKey = key;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const input = this.template.querySelector(`lightning-input[data-edit-level="${key}"]`);
            if (input) {
                input.focus();
            }
        }, 50);
    }

    handleLabelBlur(event) {
        const key = event.target.dataset.editLevel;
        const newName = event.target.value;
        const def = LEVEL_DEFAULTS.find((d) => d.key === key) || LEVEL5_DEFAULT;
        this.levels = this.levels.map((l) =>
            l.key === key ? { ...l, levelName: newName || def.defaultName } : l
        );
        this.editingLevelKey = null;
    }

    handleLabelKeyUp(event) {
        if (event.key === 'Enter') {
            event.target.blur();
        }
        if (event.key === 'Escape') {
            this.editingLevelKey = null;
        }
    }

    handleLevelValueChange(event) {
        const key = event.target.dataset.level;
        const raw = event.target.value;
        this.levels = this.levels.map((l) =>
            l.key === key ? { ...l, value: raw !== '' && raw != null ? Number(raw) : null } : l
        );
    }

    handleColorChange(event) {
        const key = event.target.dataset.level;
        this.levels = this.levels.map((l) =>
            l.key === key ? { ...l, color: event.target.value } : l
        );
    }

    handleHexInput(event) {
        const key = event.target.dataset.level;
        let hex = event.target.value;
        if (hex && !hex.startsWith('#')) {
            hex = `#${hex}`;
        }
        if (/^#[0-9A-Fa-f]{6}$/.test(hex)) {
            this.levels = this.levels.map((l) => (l.key === key ? { ...l, color: hex } : l));
        }
    }

    async handleSaveBands() {
        if (this.hasSequentialError) {
            this.showToast('Error', this.sequentialError, 'error');
            return;
        }
        this.isSavingBands = true;
        try {
            await savePerformanceBands({
                sectionId: this.selectedBandsRow.sectionId,
                subjectKey: this.selectedSubjectKey,
                bands: this._buildBandsPayloadDto()
            });
            this.showToast('Saved', 'Proficiency bands saved.', 'success');
            this.closeBandsModal();
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        }
        this.isSavingBands = false;
    }

    _mergeLevelsFromDto(dto) {
        if (!dto) {
            return null;
        }
        const byKey = new Map();
        for (const l of LEVEL_DEFAULTS) {
            byKey.set(l.key, { ...l });
        }
        if (dto.level5Min != null || dto.level5Name || dto.level5Color) {
            byKey.set('5', { ...LEVEL5_DEFAULT });
        }
        const out = [];
        for (const [key, def] of byKey.entries()) {
            const tk = DTO_THRESH_KEYS[key];
            const ck = DTO_COLOR_KEYS[key];
            const nk = DTO_NAME_KEYS[key];
            out.push({
                ...def,
                num: Number(key),
                value: dto[tk] != null ? dto[tk] : def.defaultValue,
                color: dto[ck] || def.defaultColor,
                levelName: dto[nk] || def.defaultName
            });
        }
        return out.sort((a, b) => a.num - b.num);
    }

    _buildBandsPayloadDto() {
        const byKey = new Map(this.levels.map((l) => [l.key, l]));
        const gv = (k) => {
            const l = byKey.get(k);
            return l ? l.value : null;
        };
        const gc = (k) => {
            const l = byKey.get(k);
            return l ? l.color : null;
        };
        const gn = (k) => {
            const l = byKey.get(k);
            return l ? l.levelName : null;
        };
        return {
            level1Below: gv('1'),
            level2Min: gv('2'),
            level3Min: gv('3'),
            level4Min: gv('4'),
            level5Min: byKey.has('5') ? gv('5') : null,
            level1Color: gc('1'),
            level2Color: gc('2'),
            level3Color: gc('3'),
            level4Color: gc('4'),
            level5Color: byKey.has('5') ? gc('5') : null,
            level1Name: gn('1'),
            level2Name: gn('2'),
            level3Name: gn('3'),
            level4Name: gn('4'),
            level5Name: byKey.has('5') ? gn('5') : null
        };
    }

    _applyColorPalette() {
        const count = this.levels.length;
        const palette = COLOR_PALETTES[count];
        if (!palette) {
            return;
        }
        this.levels = this.levels.map((l, index) => ({
            ...l,
            color: palette[index] || l.color
        }));
    }

    async refreshRows() {
        await refreshApex(this.wiredRowsResult);
        if (this.wiredRowsResult.data) {
            this.allRows = this.mapRows(this.wiredRowsResult.data);
            this.applyFiltersAndSort();
        }
        this.datatableRenderKey += 1;
    }

    sortData(field, direction, data) {
        const multiplier = direction === 'asc' ? 1 : -1;
        return data.sort((a, b) => {
            const valueA = a[field] != null ? a[field] : '';
            const valueB = b[field] != null ? b[field] : '';
            if (valueA === valueB) {
                return 0;
            }
            return valueA > valueB ? multiplier : -multiplier;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    extractErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        return 'An unknown error occurred.';
    }
}