import { LightningElement, wire, track } from 'lwc';
import getRows from '@salesforce/apex/NysExamsPageController.getRows';
import updateHide from '@salesforce/apex/NysExamsPageController.updateHide';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

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
    { label: 'Section Type', fieldName: 'sectionType', type: 'text', sortable: true },
    { label: 'Dashboard Widget', fieldName: 'dashboardWidget', type: 'text', sortable: true },
    {
        label: 'Hide',
        fieldName: 'hide',
        type: 'nysHideToggle',
        sortable: true,
        initialWidth: 84,
        typeAttributes: {
            sectionId: { fieldName: 'sectionId' },
            boolVal: { fieldName: 'hide' }
        }
    }
];

export default class NysExamsPage extends LightningElement {
    columns = TABLE_COLUMNS;

    @track datatableRenderKey = 0;
    allRows = [];
    rows = [];
    searchTerm = '';
    wiredRowsResult;
    isLoadingRows = true;
    sortedBy = 'name';
    sortDirection = 'asc';

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
        return `${total} NYS Exams section record(s)`;
    }

    get datatableSortedBy() {
        return this.sortedBy === 'name' ? 'nameUrl' : this.sortedBy;
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
            await refreshApex(this.wiredRowsResult);
            if (this.wiredRowsResult.data) {
                this.allRows = this.mapRows(this.wiredRowsResult.data);
                this.applyFiltersAndSort();
            }
            this.datatableRenderKey += 1;
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
            this.datatableRenderKey += 1;
        }
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