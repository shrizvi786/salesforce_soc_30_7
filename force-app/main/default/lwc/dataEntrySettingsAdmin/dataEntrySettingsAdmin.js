import { LightningElement, wire, track } from 'lwc';
import getRows from '@salesforce/apex/AssessmentDataEntrySettingsController.getRows';
import savePerformanceBands from '@salesforce/apex/AssessmentDataEntrySettingsController.savePerformanceBands';
import getPerformanceBands from '@salesforce/apex/AssessmentDataEntrySettingsController.getPerformanceBands';
import updateHideAndSync from '@salesforce/apex/AssessmentDataEntrySettingsController.updateHideAndSync';
import deleteAssessmentDataEntry from '@salesforce/apex/AssessmentDataEntrySettingsController.deleteAssessmentDataEntry';
import deleteAdministrationPeriodDataEntry from '@salesforce/apex/AssessmentDataEntrySettingsController.deleteAdministrationPeriodDataEntry';
import createDataEntryRollupGroup from '@salesforce/apex/AssessmentDataEntrySettingsController.createDataEntryRollupGroup';
import getDataEntryRollupGroupsForPicker from '@salesforce/apex/AssessmentDataEntrySettingsController.getDataEntryRollupGroupsForPicker';
import getDataEntryRollupGroupMembers from '@salesforce/apex/AssessmentDataEntrySettingsController.getDataEntryRollupGroupMembers';
import addPeriodsToDataEntryRollupGroup from '@salesforce/apex/AssessmentDataEntrySettingsController.addPeriodsToDataEntryRollupGroup';
import removeDataEntryRollupGroupMembers from '@salesforce/apex/AssessmentDataEntrySettingsController.removeDataEntryRollupGroupMembers';
import getDashboardTreeForDataEntry from '@salesforce/apex/AssessmentDataEntryDashboardController.getDashboardTreeForDataEntry';
import assignDataEntryRecord from '@salesforce/apex/AssessmentDataEntryDashboardController.assignDataEntryRecord';
import assignDataEntryRollupGroupToDashboard from '@salesforce/apex/AssessmentDataEntryDashboardController.assignDataEntryRollupGroupToDashboard';
import moveDataEntryInTree from '@salesforce/apex/AssessmentDataEntryDashboardController.moveDataEntryInTree';
import createNewMenuPage from '@salesforce/apex/AssessmentDataEntryDashboardController.createNewMenuPage';
import createNewSubmenuPage from '@salesforce/apex/AssessmentDataEntryDashboardController.createNewSubmenuPage';
import reorderNode from '@salesforce/apex/AssessmentDataEntryDashboardController.reorderNode';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Default 4 levels when the modal opens with no saved bands.
// Below Level / On Level / Above Level / Level 4; Level 5 is optional via Add button.
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

function hexToRgba(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

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

const PAGE_SIZE_OPTIONS = [
    { label: '10', value: '10' },
    { label: '25', value: '25' },
    { label: '50', value: '50' },
    { label: '100', value: '100' }
];

const TABLE_COLUMNS = [
    { label: 'Assessment Name', fieldName: 'assessmentName', type: 'text', wrapText: true, sortable: true },
    {
        label: 'Administration Period Name',
        fieldName: 'administrationPeriodName',
        type: 'text',
        wrapText: true,
        sortable: true
    },
    { label: 'School DBN', fieldName: 'dbn', type: 'text', sortable: true },
    { label: 'Academic Year', fieldName: 'academicYear', type: 'text', sortable: true },
    { label: 'Subject', fieldName: 'subject', type: 'text', sortable: true },
    { label: 'Grade', fieldName: 'grade', type: 'text', sortable: true, initialWidth: 88 },
    {
        label: 'Hide',
        fieldName: 'hide',
        type: 'dataEntryBoolToggle',
        sortable: true,
        initialWidth: 84,
        typeAttributes: {
            recordId: { fieldName: 'administrationPeriodId' },
            boolVal: { fieldName: 'hide' },
            mode: 'hide'
        }
    },
    {
        label: 'Edit',
        type: 'dataEntryPerfBand',
        sortable: false,
        initialWidth: 120,
        typeAttributes: {
            recordId: { fieldName: 'administrationPeriodId' }
        }
    },
    {
        label: 'Assign',
        type: 'dataEntryAssignBtn',
        sortable: false,
        initialWidth: 120,
        typeAttributes: {
            recordId: { fieldName: 'administrationPeriodId' }
        }
    },
    {
        label: 'Delete',
        type: 'dataEntryDeleteBtn',
        sortable: false,
        initialWidth: 120,
        typeAttributes: {
            recordId: { fieldName: 'administrationPeriodId' }
        }
    }
];

const EXPAND_DELAY_MS = 700;

/** School year rolls on July 15 (month is 0-based in JS). */
function getCurrentAcademicYear() {
    const today = new Date();
    const calendarYear = today.getFullYear();
    const startYear =
        today.getMonth() > 6 || (today.getMonth() === 6 && today.getDate() >= 15)
            ? calendarYear
            : calendarYear - 1;
    return `${startYear}-${startYear + 1}`;
}

const DEFAULT_ACADEMIC_YEAR = getCurrentAcademicYear();
const ACADEMIC_YEAR_OPTIONS = [
    { label: '2022-2023', value: '2022-2023' },
    { label: '2023-2024', value: '2023-2024' },
    { label: '2024-2025', value: '2024-2025' },
    { label: '2025-2026', value: '2025-2026' },
    { label: '2026-2027', value: '2026-2027' },
    { label: '2027-2028', value: '2027-2028' },
    { label: '2028-2029', value: '2028-2029' }
];

const MEMBER_COLUMNS = [
    {
        label: 'Administration Period',
        fieldName: 'administrationPeriodName',
        type: 'text',
        wrapText: true,
        sortable: true
    },
    { label: 'Assessment Name', fieldName: 'assessmentName', type: 'text', wrapText: true, sortable: true },
    { label: 'DBN', fieldName: 'dbn', type: 'text', sortable: true }
];

export default class DataEntrySettingsAdmin extends LightningElement {
    columns = TABLE_COLUMNS;
    memberColumns = MEMBER_COLUMNS;
    pageSizeOptions = PAGE_SIZE_OPTIONS;
    maxRowSelection = 2000;

    /** Bump after saves/toggles so the datatable remounts (checkbox state + clears stale UI). */
    @track datatableRenderKey = 0;

    selectedRowKeys = [];
    isGroupModalOpen = false;
    groupNameInput = '';
    isCreatingRollupGroup = false;
    rollupGroupOptions = [];
    rollupGroupSearchTerm = '';
    isRollupGroupListOpen = false;
    selectedRollupGroupId = '';
    groupMemberRows = [];
    isLoadingRollupMembers = false;
    isRollupGroupActionPending = false;
    selectedMemberRowIds = [];
    memberDatatableKey = 0;
    assignMode = 'single';

    _allRows = [];
    _filteredRows = [];
    dbnSearchTerm = '';
    assessmentSearchTerm = '';
    currentPage = 1;
    pageSize = 10;
    wiredRowsResult;
    isLoadingRows = true;
    sortedBy = 'assessmentName';
    sortDirection = 'asc';

    isAssignModalOpen = false;
    selectedAssignRow = null;
    selectedAcademicYear = DEFAULT_ACADEMIC_YEAR;
    academicYearOptions = ACADEMIC_YEAR_OPTIONS;

    isBandsModalOpen = false;
    isBandsLoading = false;
    isSavingBands = false;
    selectedBandsRow = null;
    editingLevelKey = null;
    @track levels = [];

    @track treeData = [];
    isTreeLoading = false;
    isPlaced = false;

    isDragging = false;
    dragType = '';
    dragItemData = null;
    _expandTimers = {};
    _autoExpandedIds = new Map();
    _scrollRafId = null;

    // Context menu state
    showContextMenu = false;
    contextMenuX = 0;
    contextMenuY = 0;
    contextNodeId = '';
    contextNodeLevel = 0;
    contextNodeLabel = '';
    contextCreateType = '';
    contextParentSectionId = '';
    showNewItemInput = false;
    newItemName = '';

    @wire(getRows)
    wiredRows(result) {
        this.wiredRowsResult = result;
        if (result.data) {
            this._allRows = [...result.data];
            this.applyFiltersAndSort();
            this.isLoadingRows = false;
        } else if (result.error) {
            this.isLoadingRows = false;
            // eslint-disable-next-line no-console
            console.error(result.error);
        }
    }

    get hasRows() {
        return this._filteredRows && this._filteredRows.length > 0;
    }

    get hasAnyRows() {
        return this._allRows && this._allRows.length > 0;
    }

    get showNoSearchResults() {
        return this.hasAnyRows && !this.hasRows && this.hasActiveTableFilter;
    }

    get hasActiveTableFilter() {
        return !!(this.dbnSearchTerm && this.dbnSearchTerm.trim())
            || !!(this.assessmentSearchTerm && this.assessmentSearchTerm.trim());
    }

    get isClearFilterDisabled() {
        return !this.hasActiveTableFilter;
    }

    get activeFilterSummary() {
        const parts = [];
        const dbn = (this.dbnSearchTerm || '').trim();
        const assessment = (this.assessmentSearchTerm || '').trim();
        if (dbn) {
            parts.push(`DBN contains "${dbn}"`);
        }
        if (assessment) {
            parts.push(`Assessment name contains "${assessment}"`);
        }
        return parts.join(' · ');
    }

    get paginatedRows() {
        const start = (this.currentPage - 1) * this.pageSize;
        return (this._filteredRows || []).slice(start, start + this.pageSize);
    }

    get totalPages() {
        const total = (this._filteredRows || []).length;
        return total === 0 ? 1 : Math.ceil(total / this.pageSize);
    }

    get showingRange() {
        const filtered = this._filteredRows || [];
        if (filtered.length === 0) {
            return 'No results';
        }
        const start = (this.currentPage - 1) * this.pageSize + 1;
        const end = Math.min(this.currentPage * this.pageSize, filtered.length);
        return `Showing ${start}\u2013${end} of ${filtered.length}`;
    }

    get isPrevDisabled() {
        return this.currentPage <= 1;
    }

    get isNextDisabled() {
        return this.currentPage >= this.totalPages;
    }

    get pageSizeValue() {
        return String(this.pageSize);
    }

    get hasTreeData() {
        return this.treeData && this.treeData.length > 0;
    }

    get dragCardClass() {
        const activeType = this.assignMode === 'group' ? 'rollup-group' : 'ade-new';
        return this.isDragging && this.dragType === activeType
            ? 'drag-card drag-card-dragging'
            : 'drag-card';
    }

    get isGroupButtonDisabled() {
        return !this.selectedRowKeys || this.selectedRowKeys.length < 2;
    }

    get groupModalTitle() {
        const count = this.selectedRowKeys ? this.selectedRowKeys.length : 0;
        return `Create data entry group (${count} selected)`;
    }

    get isCreateGroupDisabled() {
        return this.isCreatingRollupGroup || !(this.groupNameInput && this.groupNameInput.trim());
    }

    get hasRollupGroupSelected() {
        return !!this.selectedRollupGroupId;
    }

    get selectedRollupGroupName() {
        const group = (this.rollupGroupOptions || []).find(
            option => option.value === this.selectedRollupGroupId
        );
        return group && group.label ? group.label : 'Selected group';
    }

    get memberMaxRowSelection() {
        return 500;
    }

    get isAddToRollupGroupDisabled() {
        return (
            this.isRollupGroupActionPending ||
            !this.hasRollupGroupSelected ||
            !this.selectedRowKeys ||
            this.selectedRowKeys.length < 1
        );
    }

    get isRemoveFromRollupGroupDisabled() {
        return (
            this.isRollupGroupActionPending ||
            !this.hasRollupGroupSelected ||
            !this.selectedMemberRowIds ||
            this.selectedMemberRowIds.length < 1
        );
    }

    get isAssignGroupToDashboardDisabled() {
        return (
            !this.hasRollupGroupSelected ||
            !this.groupMemberRows ||
            this.groupMemberRows.length === 0 ||
            this.isRollupGroupActionPending
        );
    }

    get filteredRollupGroupRows() {
        const q = (this.rollupGroupSearchTerm || '').trim().toLowerCase();
        const base = this.rollupGroupOptions || [];
        const filtered = !q ? base : base.filter(o => (o.label || '').toLowerCase().includes(q));
        return filtered.map(o => ({
            label: o.label,
            value: o.value,
            rowClass:
                o.value === this.selectedRollupGroupId
                    ? 'group-picker-row is-selected'
                    : 'group-picker-row'
        }));
    }

    get rollupGroupPickerEmpty() {
        return !this.filteredRollupGroupRows || this.filteredRollupGroupRows.length === 0;
    }

    get rollupGroupDropdownEmpty() {
        return this.isRollupGroupListOpen && this.rollupGroupPickerEmpty;
    }

    get assignModalTitle() {
        return this.assignMode === 'group'
            ? 'Assign data entry group to dashboard'
            : 'Assign assessment data entry to dashboard';
    }

    get assignDragLabel() {
        if (this.assignMode === 'group' && this.selectedAssignRow) {
            return this.selectedAssignRow.assessmentName;
        }
        return this.selectedAssignRow ? this.selectedAssignRow.assessmentName : '';
    }

    connectedCallback() {
        this.loadRollupGroupOptions();
    }

    async loadRollupGroupOptions() {
        try {
            this.rollupGroupOptions = await getDataEntryRollupGroupsForPicker();
        } catch (error) {
            this.rollupGroupOptions = [];
        }
    }

    async loadRollupGroupMembers() {
        if (!this.selectedRollupGroupId) {
            this.groupMemberRows = [];
            return;
        }
        this.isLoadingRollupMembers = true;
        try {
            this.groupMemberRows = await getDataEntryRollupGroupMembers({
                groupId: this.selectedRollupGroupId
            });
        } catch (error) {
            this.groupMemberRows = [];
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isLoadingRollupMembers = false;
        }
    }

    async _loadRollupGroupMembersWithRetry(maxAttempts = 6, delayMs = 400) {
        for (let attempt = 0; attempt < maxAttempts; attempt++) {
            await this.loadRollupGroupMembers();
            if (this.groupMemberRows && this.groupMemberRows.length > 0) {
                return;
            }
            if (attempt < maxAttempts - 1) {
                await new Promise(resolve => setTimeout(resolve, delayMs));
            }
        }
    }

    // ── Table handlers ──

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortDirection = sortDirection;
        this.currentPage = 1;
        this.applyFiltersAndSort();
    }

    handleDbnSearchChange(event) {
        this.dbnSearchTerm = event.target.value || '';
        this.currentPage = 1;
        this._clearTableSelection();
        this.applyFiltersAndSort();
    }

    handleAssessmentSearchChange(event) {
        this.assessmentSearchTerm = event.target.value || '';
        this.currentPage = 1;
        this._clearTableSelection();
        this.applyFiltersAndSort();
    }

    handleClearTableFilter() {
        this.dbnSearchTerm = '';
        this.assessmentSearchTerm = '';
        this.currentPage = 1;
        this._clearTableSelection();
        this.applyFiltersAndSort();
    }

    handleRowSelection(event) {
        const selected = event.detail.selectedRows || [];
        this.selectedRowKeys = selected.map(row => row.rowKey);
    }

    _clearTableSelection() {
        this.selectedRowKeys = [];
        this.datatableRenderKey += 1;
    }

    openGroupModal() {
        if (this.isGroupButtonDisabled) {
            return;
        }
        this.groupNameInput = '';
        this.isGroupModalOpen = true;
    }

    closeGroupModal() {
        this.isGroupModalOpen = false;
        this.groupNameInput = '';
        this.isCreatingRollupGroup = false;
    }

    handleGroupNameChange(event) {
        this.groupNameInput = event.target.value;
    }

    async handleCreateRollupGroup() {
        if (this.isCreateGroupDisabled) {
            return;
        }
        const selectedRows = (this._allRows || []).filter(row =>
            this.selectedRowKeys.includes(row.rowKey)
        );
        const members = selectedRows
            .filter(row => row.administrationPeriodId)
            .map(row => ({
                administrationPeriodName: row.administrationPeriodName,
                dbn: row.dbn,
                assessmentPeriodId: row.administrationPeriodId
            }));
        if (members.length < 2) {
            this.showToast(
                'Error',
                'Select at least two rows that have an administration period.',
                'error'
            );
            return;
        }

        this.isCreatingRollupGroup = true;
        try {
            const groupId = await createDataEntryRollupGroup({
                groupName: this.groupNameInput.trim(),
                members
            });
            this.showToast('Success', 'Group created successfully.', 'success');
            this.closeGroupModal();
            this._clearTableSelection();
            if (groupId) {
                this.selectedRollupGroupId = groupId;
            }
            await this.loadRollupGroupOptions();
            this._syncRollupGroupSearchFromSelection();
            await this._loadRollupGroupMembersWithRetry();
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isCreatingRollupGroup = false;
        }
    }

    handleRollupGroupSearch(event) {
        this.rollupGroupSearchTerm = event.target.value || '';
        this.isRollupGroupListOpen = true;
    }

    handleRollupGroupSearchFocus() {
        this.isRollupGroupListOpen = true;
    }

    handleRollupGroupSearchBlur(event) {
        const panel = this.template.querySelector('[data-rollup-picker-panel]');
        const relatedTarget = event.relatedTarget;
        if (panel && relatedTarget && typeof relatedTarget === 'object' && panel.contains(relatedTarget)) {
            return;
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const active = this.template.activeElement;
            if (panel && active && panel.contains(active)) {
                return;
            }
            this.isRollupGroupListOpen = false;
        }, 0);
    }

    async handlePickRollupGroup(event) {
        const groupId = event.currentTarget.dataset.id;
        if (!groupId) {
            return;
        }
        const previous = this.selectedRollupGroupId;
        this.selectedRollupGroupId = groupId;
        this.isRollupGroupListOpen = false;
        this._syncRollupGroupSearchFromSelection();
        if (groupId !== previous) {
            this._clearMemberSelection();
            await this.loadRollupGroupMembers();
        }
    }

    handleRefreshRollupGroups() {
        this.loadRollupGroupOptions();
    }

    async handleRefreshMembers() {
        await this.loadRollupGroupMembers();
    }

    handleMemberRowSelection(event) {
        const rows = event.detail.selectedRows || [];
        this.selectedMemberRowIds = rows.map(row => row.id);
    }

    _clearMemberSelection() {
        this.selectedMemberRowIds = [];
        this.memberDatatableKey += 1;
    }

    async handleAddToRollupGroup() {
        if (this.isAddToRollupGroupDisabled) {
            return;
        }
        const selectedRows = (this._allRows || []).filter(row =>
            this.selectedRowKeys.includes(row.rowKey)
        );
        const periodIds = selectedRows
            .map(row => row.administrationPeriodId)
            .filter(Boolean);
        if (!periodIds.length) {
            this.showToast(
                'Error',
                'Select at least one row that has an administration period.',
                'error'
            );
            return;
        }

        this.isRollupGroupActionPending = true;
        try {
            const result = await addPeriodsToDataEntryRollupGroup({
                groupId: this.selectedRollupGroupId,
                administrationPeriodIds: periodIds
            });
            const added = result?.addedCount ?? 0;
            const skipped = result?.skippedDuplicateCount ?? 0;
            let msg = `${added} period${added === 1 ? '' : 's'} added to the group.`;
            if (skipped > 0) {
                msg += ` ${skipped} skipped (already in group).`;
            }
            this.showToast('Success', msg, 'success');
            this._clearTableSelection();
            this.memberDatatableKey += 1;
            await this.loadRollupGroupMembers();
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        }
        this.isRollupGroupActionPending = false;
    }

    async handleRemoveFromRollupGroup() {
        if (this.isRemoveFromRollupGroupDisabled) {
            return;
        }
        this.isRollupGroupActionPending = true;
        try {
            await removeDataEntryRollupGroupMembers({
                groupId: this.selectedRollupGroupId,
                rollupAssessmentRecordIds: this.selectedMemberRowIds
            });
            this.showToast('Success', 'Selected periods were removed from the group.', 'success');
            this._clearMemberSelection();
            this.memberDatatableKey += 1;
            await this.loadRollupGroupMembers();
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        }
        this.isRollupGroupActionPending = false;
    }

    _syncRollupGroupSearchFromSelection() {
        if (!this.selectedRollupGroupId) {
            return;
        }
        const selected = (this.rollupGroupOptions || []).find(
            option => option.value === this.selectedRollupGroupId
        );
        if (selected && selected.label) {
            this.rollupGroupSearchTerm = selected.label;
        }
    }

    async openGroupAssignModal() {
        if (this.isAssignGroupToDashboardDisabled) {
            return;
        }
        const dbn = this._getDbnForSelectedRollupGroup();
        if (!dbn) {
            this.showToast('Error', 'Could not determine DBN from group members.', 'error');
            return;
        }
        const group = (this.rollupGroupOptions || []).find(
            option => option.value === this.selectedRollupGroupId
        );
        this.assignMode = 'group';
        this.selectedAssignRow = {
            assessmentName: group ? group.label : 'Data entry group',
            dbn,
            recordId: null
        };
        this.isAssignModalOpen = true;
        this.selectedAcademicYear = DEFAULT_ACADEMIC_YEAR;
        this.isTreeLoading = true;
        this.isPlaced = false;
        this.treeData = [];
        this._autoExpandedIds = new Map();
        try {
            await this._loadDashboardTreeForAssign(dbn);
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    _getDbnForSelectedRollupGroup() {
        const rows = this.groupMemberRows || [];
        if (!rows.length) {
            return '';
        }
        return rows[0].dbn || rows[0].DBN__c || '';
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value, 10);
        this.currentPage = 1;
    }

    handlePrevPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
        }
    }

    applyFiltersAndSort() {
        let data = [...(this._allRows || [])];
        const dbnTerm = (this.dbnSearchTerm || '').trim().toLowerCase();
        const assessmentTerm = (this.assessmentSearchTerm || '').trim().toLowerCase();

        if (dbnTerm) {
            data = data.filter(row => (row.dbn || '').toString().toLowerCase().includes(dbnTerm));
        }
        if (assessmentTerm) {
            data = data.filter(row =>
                (row.assessmentName || '').toString().toLowerCase().includes(assessmentTerm)
            );
        }

        this._filteredRows = this.sortData(this.sortedBy, this.sortDirection, data);
        if (this.currentPage > this.totalPages) {
            this.currentPage = this.totalPages;
        }
    }

    async handleRecordDelete(event) {
        const periodId = event.detail.recordId;
        if (!periodId) {
            this.showToast(
                'Error',
                'Delete requires an administration period on this row.',
                'error'
            );
            return;
        }

        const row = this._allRows.find(r => r.administrationPeriodId === periodId);
        const periodLabel = row && row.administrationPeriodName ? row.administrationPeriodName : 'this period';
        const assessmentLabel = row && row.assessmentName ? row.assessmentName : 'assessment';
        const confirmed = window.confirm(
            `Delete "${periodLabel}" for ${assessmentLabel}? This removes only this administration period and its dashboard placement.`
        );
        if (!confirmed) {
            return;
        }

        try {
            await deleteAdministrationPeriodDataEntry({ administrationPeriodId: periodId });
            this.showToast('Deleted', 'Administration period removed.', 'success');
            await refreshApex(this.wiredRowsResult);
            this.datatableRenderKey += 1;
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        }
    }

    async handleRecordToggle(event) {
        const { recordId, mode, value } = event.detail || {};
        if (!recordId || mode !== 'hide') {
            if (mode === 'hide' && !recordId) {
                this.showToast(
                    'Error',
                    'Hide requires an administration period on this row.',
                    'error'
                );
            }
            return;
        }

        try {
            await updateHideAndSync({ administrationPeriodId: recordId, hideVal: value });
            this.showToast('Saved', 'Hide updated.', 'success');
            await refreshApex(this.wiredRowsResult);
            this.datatableRenderKey += 1;
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
            this.datatableRenderKey += 1;
        }
    }

    handleRecordEdit(event) {
        const periodId = event.detail.recordId;
        if (!periodId) {
            this.showToast(
                'Error',
                'Performance bands require an administration period on this row.',
                'error'
            );
            return;
        }
        const row = this._allRows.find(r => r.administrationPeriodId === periodId);
        if (row) {
            this.openBandsModal(row);
        }
    }

    handleRecordAssign(event) {
        const periodId = event.detail.recordId;
        if (!periodId) {
            this.showToast(
                'Error',
                'Assign requires an administration period on this row.',
                'error'
            );
            return;
        }
        const row = this._allRows.find(r => r.administrationPeriodId === periodId);
        if (row) {
            this.openAssignModal(row);
        }
    }

    // ── Assign modal lifecycle ──

    async openAssignModal(row) {
        if (!row.administrationPeriodId) {
            this.showToast(
                'Error',
                'Assign requires an administration period on this row.',
                'error'
            );
            return;
        }
        this.assignMode = 'single';
        this.selectedAssignRow = row;
        this.selectedAcademicYear = DEFAULT_ACADEMIC_YEAR;
        this.isAssignModalOpen = true;
        this.isTreeLoading = true;
        this.isPlaced = false;
        this.treeData = [];
        this._autoExpandedIds = new Map();

        try {
            await this._loadDashboardTreeForAssign(row.dbn);
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    async handleAcademicYearChange(event) {
        this.selectedAcademicYear = event.detail.value;
        if (!this.selectedAssignRow?.dbn) {
            return;
        }
        this.isTreeLoading = true;
        this._autoExpandedIds = new Map();
        try {
            await this._loadDashboardTreeForAssign(this.selectedAssignRow.dbn);
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    async _loadDashboardTreeForAssign(dbn) {
        const tree = await getDashboardTreeForDataEntry({
            dbn,
            academicYear: this.selectedAcademicYear
        });
        this.treeData = this._initTree(tree);
    }

    closeAssignModal() {
        this.isAssignModalOpen = false;
        this.assignMode = 'single';
        this.selectedAssignRow = null;
        this.selectedAcademicYear = DEFAULT_ACADEMIC_YEAR;
        this.treeData = [];
        this.isPlaced = false;
        this.isDragging = false;
        this.dragType = '';
        this.dragItemData = null;
        this._autoExpandedIds = new Map();
        this.showContextMenu = false;
        this.showNewItemInput = false;
        this.newItemName = '';
        this.contextCreateType = '';
        this._clearAllTimers();
        this._stopAutoScroll();
        return refreshApex(this.wiredRowsResult);
    }

    // ── Tree data helpers ──

    _initTree(nodes) {
        if (!nodes) return [];
        return nodes.map(n => ({
            ...n,
            expanded: false,
            children: n.children ? this._initTree(n.children) : []
        }));
    }

    _toggleNode(nodes, targetId) {
        return nodes.map(n => {
            if (n.id === targetId) {
                return { ...n, expanded: !n.expanded };
            }
            if (n.children && n.children.length > 0) {
                return { ...n, children: this._toggleNode(n.children, targetId) };
            }
            return n;
        });
    }

    _expandNode(nodes, targetId) {
        return nodes.map(n => {
            if (n.id === targetId) {
                return { ...n, expanded: true };
            }
            if (n.children && n.children.length > 0) {
                return { ...n, children: this._expandNode(n.children, targetId) };
            }
            return n;
        });
    }

    _collapseNode(nodes, targetId) {
        return nodes.map(n => {
            if (n.id === targetId) {
                return { ...n, expanded: false };
            }
            if (n.children && n.children.length > 0) {
                return { ...n, children: this._collapseNode(n.children, targetId) };
            }
            return n;
        });
    }

    // ── Flat tree for rendering ──

    get flatTreeItems() {
        const items = [];
        const dbn = this.selectedAssignRow ? this.selectedAssignRow.dbn : '';
        this._buildFlat(this.treeData, 1, dbn, 'top', items);
        return items;
    }

    _buildFlat(nodes, indent, parentId, targetLevel, result) {
        if (!nodes || nodes.length === 0) {
            result.push(this._makeDropZone(
                'dz-empty-' + parentId, indent, parentId, targetLevel, 0, 1, true
            ));
            return;
        }

        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];
            const prevSort = i > 0 ? nodes[i - 1].sortOrder : 0;

            result.push(this._makeDropZone(
                'dz-before-' + node.id, indent, parentId, targetLevel,
                prevSort, node.sortOrder, false
            ));

            const isMenu = node.nodeType === 'Menu';
            const expanded = node.expanded === true;

            const dataEntryId = node.dataEntryId || '';
            const highlightPlacement = node.isAssessment === true || !!node.dataEntryId;

            result.push({
                key: node.id,
                isDropZone: false,
                isNode: true,
                id: node.id,
                label: node.label,
                isMenu,
                level: node.level,
                parentId,
                sortOrder: node.sortOrder,
                isAssessment: node.isAssessment === true,
                assessmentId: node.assessmentId,
                dataEntryId,
                draggableStr: 'true',
                isMenuStr: isMenu ? 'true' : 'false',
                expandIcon: expanded ? 'utility:chevrondown' : 'utility:chevronright',
                nodeClass: 'tree-node' +
                    (indent > 0 ? ' indent-' + indent : '') +
                    (isMenu ? ' tree-node-folder' : '') +
                    (highlightPlacement ? ' tree-node-assessment' : ''),
                labelClass: 'node-label' + (isMenu ? ' folder-label' : '')
            });

            if (isMenu && expanded) {
                const childLevel = targetLevel === 'top' ? 'level1' : 'level2';
                if (node.children && node.children.length > 0) {
                    this._buildFlat(node.children, indent + 1, node.id, childLevel, result);
                }
                const lastChild = node.children && node.children.length > 0
                    ? node.children[node.children.length - 1] : null;
                const endPrev = lastChild ? lastChild.sortOrder : 0;
                result.push(this._makeDropZone(
                    'dz-end-' + node.id, indent + 1, node.id, childLevel,
                    endPrev, endPrev + 1, !lastChild
                ));
            }
        }

        if (targetLevel === 'top' && nodes.length > 0) {
            const last = nodes[nodes.length - 1];
            result.push(this._makeDropZone(
                'dz-end-root', 1, parentId, targetLevel,
                last.sortOrder, last.sortOrder + 1, false
            ));
        }
    }

    _makeDropZone(key, indent, parentId, targetLevel, prevSort, nextSort, isEmpty) {
        let cls = isEmpty ? 'drop-zone drop-zone-empty' : 'drop-zone';
        if (indent > 0) cls += ' indent-' + indent;
        return {
            key,
            isDropZone: true,
            isNode: false,
            parentId,
            targetLevel,
            prevSort: String(prevSort),
            nextSort: String(nextSort),
            isEmpty,
            dropZoneClass: cls
        };
    }

    // ── Tree interaction ──

    handleToggleExpand(event) {
        event.stopPropagation();
        const nodeId = event.currentTarget.dataset.id;
        this.treeData = this._toggleNode(this.treeData, nodeId);
    }

    // ── Drag: new assessment ──

    handleDragStart(event) {
        this.isDragging = true;
        this.dragType = this.assignMode === 'group' ? 'rollup-group' : 'ade-new';
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', this.dragType);
        this._addDraggingClass();
    }

    // ── Drag: existing placed HMH row ──

    handleTreeItemDragStart(event) {
        const el = event.currentTarget;
        const dataEntryId = el.dataset.dataEntryId;
        const hasDataEntry = dataEntryId && dataEntryId !== 'null' && dataEntryId !== 'undefined';
        this.isDragging = true;
        this.dragType = hasDataEntry ? 'ade-move' : 'reorder';
        this.dragItemData = {
            id: el.dataset.id,
            level: parseInt(el.dataset.level, 10),
            label: el.dataset.label,
            dataEntryId,
            isDataEntryMove: hasDataEntry
        };
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', hasDataEntry ? 'ade-move' : 'reorder-node');
        this._addDraggingClass();
    }

    handleDragEnd() {
        this.isDragging = false;
        this.dragType = '';
        this.dragItemData = null;
        this._autoExpandedIds = new Map();
        this._removeDraggingClass();
        this._clearAllTimers();
        this._stopAutoScroll();
        const active = this.template.querySelectorAll('.drop-zone-active');
        active.forEach(el => el.classList.remove('drop-zone-active'));
    }

    // ── Auto-scroll during drag ──

    handleTreeDragOver(event) {
        event.preventDefault();
        if (!this.isDragging) return;

        const mouseY = event.clientY;
        const edgeZone = 60;
        const maxSpeed = 14;

        const treeEl = this.template.querySelector('.tree-container');
        const modalEl = this.template.querySelector('.slds-modal__content');

        let treeDelta = 0;
        let modalDelta = 0;

        if (treeEl) {
            const r = treeEl.getBoundingClientRect();
            if (mouseY < r.top + edgeZone && mouseY >= r.top) {
                treeDelta = -maxSpeed * ((r.top + edgeZone - mouseY) / edgeZone);
            } else if (mouseY > r.bottom - edgeZone && mouseY <= r.bottom) {
                treeDelta = maxSpeed * ((mouseY - (r.bottom - edgeZone)) / edgeZone);
            }
        }

        if (modalEl) {
            const r = modalEl.getBoundingClientRect();
            if (mouseY < r.top + edgeZone && mouseY >= r.top) {
                modalDelta = -maxSpeed * ((r.top + edgeZone - mouseY) / edgeZone);
            } else if (mouseY > r.bottom - edgeZone && mouseY <= r.bottom) {
                modalDelta = maxSpeed * ((mouseY - (r.bottom - edgeZone)) / edgeZone);
            }
        }

        if (treeDelta !== 0 || modalDelta !== 0) {
            this._startAutoScroll(treeEl, treeDelta, modalEl, modalDelta);
        } else {
            this._stopAutoScroll();
        }
    }

    _startAutoScroll(treeEl, treeDelta, modalEl, modalDelta) {
        this._stopAutoScroll();
        const scroll = () => {
            if (treeEl && treeDelta !== 0) treeEl.scrollTop += treeDelta;
            if (modalEl && modalDelta !== 0) modalEl.scrollTop += modalDelta;
            this._scrollRafId = requestAnimationFrame(scroll);
        };
        this._scrollRafId = requestAnimationFrame(scroll);
    }

    _stopAutoScroll() {
        if (this._scrollRafId) {
            cancelAnimationFrame(this._scrollRafId);
            this._scrollRafId = null;
        }
    }

    // ── Drop zone handlers ──

    handleDropZoneDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
    }

    handleDropZoneDragEnter(event) {
        event.preventDefault();
        event.currentTarget.classList.add('drop-zone-active');
    }

    handleDropZoneDragLeave(event) {
        event.currentTarget.classList.remove('drop-zone-active');
    }

    async handleDropZoneDrop(event) {
        event.preventDefault();
        event.currentTarget.classList.remove('drop-zone-active');
        this._removeDraggingClass();
        this._stopAutoScroll();

        if (!this.isDragging) return;

        const ds = event.currentTarget.dataset;
        const parentId = ds.parentId;
        const targetLevel = ds.targetLevel;
        const prevSort = parseFloat(ds.prevSort);
        const nextSort = parseFloat(ds.nextSort);
        const newSort = Math.round(((prevSort + nextSort) / 2) * 10000) / 10000;

        if (this.dragType === 'ade-new' || this.dragType === 'rollup-group') {
            await this._placeNewRecord(parentId, targetLevel, newSort);
        } else if (this.dragType === 'ade-move' && this.dragItemData) {
            await this._moveRecordInTree(parentId, targetLevel, newSort);
        } else if (this.dragType === 'reorder' && this.dragItemData) {
            await this._reorderExisting(newSort);
        }

        this.isDragging = false;
        this.dragType = '';
        this.dragItemData = null;
        this._autoExpandedIds = new Map();
    }

    // ── Node hover: auto-expand on drag, auto-collapse siblings ──

    handleNodeDragEnter(event) {
        event.preventDefault();
        const nodeId = event.currentTarget.dataset.id;
        if (!nodeId || !this.isDragging) return;

        const node = this._findNode(this.treeData, nodeId);
        if (!node) return;

        const nodeLevel = node.level;

        // Collapse all auto-expanded nodes at this level or deeper
        let updatedTree = this.treeData;
        const toRemove = [];
        for (const [expandedId, expandedLevel] of this._autoExpandedIds) {
            if (expandedLevel >= nodeLevel && expandedId !== nodeId) {
                updatedTree = this._collapseNode(updatedTree, expandedId);
                toRemove.push(expandedId);
            }
        }
        if (toRemove.length > 0) {
            toRemove.forEach(id => this._autoExpandedIds.delete(id));
            this.treeData = updatedTree;
        }

        // Clear any pending timer for other nodes, start timer for this one
        Object.keys(this._expandTimers).forEach(timerId => {
            if (timerId !== nodeId) {
                clearTimeout(this._expandTimers[timerId]);
                delete this._expandTimers[timerId];
            }
        });

        if (node.nodeType === 'Menu' && !node.expanded) {
            if (this._expandTimers[nodeId]) {
                clearTimeout(this._expandTimers[nodeId]);
            }
            this._expandTimers[nodeId] = setTimeout(() => {
                this.treeData = this._expandNode(this.treeData, nodeId);
                this._autoExpandedIds.set(nodeId, nodeLevel);
                delete this._expandTimers[nodeId];
            }, EXPAND_DELAY_MS);
        }
    }

    handleNodeDragLeave(event) {
        const nodeId = event.currentTarget.dataset.id;
        if (nodeId && this._expandTimers[nodeId]) {
            clearTimeout(this._expandTimers[nodeId]);
            delete this._expandTimers[nodeId];
        }
    }

    // ── Placement logic ──

    async _placeNewRecord(parentId, targetLevel, sortOrder) {
        this.isTreeLoading = true;
        try {
            if (this.assignMode === 'group') {
                const periodNames = (this.groupMemberRows || [])
                    .map(row => row.administrationPeriodName)
                    .filter(Boolean);
                await assignDataEntryRollupGroupToDashboard({
                    rollupGroupId: this.selectedRollupGroupId,
                    placementLevel: targetLevel,
                    parentMenuSectionId: targetLevel === 'level1' ? parentId : null,
                    dbn: this.selectedAssignRow.dbn,
                    includedAdministrationPeriodNames: periodNames,
                    academicYear: this.selectedAcademicYear
                });
                this.showToast(
                    'Success',
                    `"${this.selectedAssignRow.assessmentName}" placed on the dashboard.`,
                    'success'
                );
                await this.loadRollupGroupOptions();
                await this.loadRollupGroupMembers();
            } else {
                await assignDataEntryRecord({
                    administrationPeriodId: this.selectedAssignRow.administrationPeriodId,
                    parentId,
                    selectedLevel: targetLevel,
                    sortOrder,
                    academicYear: this.selectedAcademicYear
                });
                const placedLabel =
                    this.selectedAssignRow.administrationPeriodName ||
                    this.selectedAssignRow.assessmentName;
                this.showToast(
                    'Success',
                    `"${placedLabel}" placed successfully.`,
                    'success'
                );
            }
            this.isPlaced = true;

            await this._loadDashboardTreeForAssign(this.selectedAssignRow.dbn);
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    async _moveRecordInTree(parentId, targetLevel, sortOrder) {
        this.isTreeLoading = true;
        const data = this.dragItemData;
        try {
            await moveDataEntryInTree({
                administrationPeriodId: data.dataEntryId,
                existingRecordId: data.id,
                fromLevel: data.level,
                newParentId: parentId,
                toLevel: targetLevel,
                sortOrder,
                academicYear: this.selectedAcademicYear
            });

            this.showToast('Success', `"${data.label}" moved.`, 'success');

            await this._loadDashboardTreeForAssign(this.selectedAssignRow.dbn);
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    async _reorderExisting(sortOrder) {
        this.isTreeLoading = true;
        const data = this.dragItemData;
        try {
            await reorderNode({
                recordId: data.id,
                level: data.level,
                newSortOrder: sortOrder
            });

            this.showToast('Success', `"${data.label}" reordered.`, 'success');

            await this._loadDashboardTreeForAssign(this.selectedAssignRow.dbn);
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    // ── Tree search ──

    _findNode(nodes, id) {
        for (const n of nodes) {
            if (n.id === id) return n;
            if (n.children) {
                const found = this._findNode(n.children, id);
                if (found) return found;
            }
        }
        return null;
    }

    // ── Context menu (right-click to add menu item) ──

    _positionContextMenu() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        Promise.resolve().then(() => {
            const menu = this.template.querySelector('.ctx-menu');
            if (menu) {
                menu.style.left = this.contextMenuX + 'px';
                menu.style.top = this.contextMenuY + 'px';
            }
        });
    }

    get contextMenuLabel() {
        return this.contextCreateType === 'submenu' ? 'Create new sub-menu' : 'Create new menu';
    }

    get contextInputPlaceholder() {
        return this.contextCreateType === 'submenu' ? 'Enter sub-menu name' : 'Enter menu name';
    }

    get isNewItemSaveDisabled() {
        return !this.newItemName || !this.newItemName.trim();
    }

    handleTreeContextMenu(event) {
        event.preventDefault();
        event.stopPropagation();
        const el = event.currentTarget;
        const level = parseInt(el.dataset.level, 10);
        const isMenu = el.dataset.isMenu === 'true';

        // Only Level 1 Menu-type nodes can have sub-menus created inside them
        if (level !== 1 || !isMenu) return;

        const container = this.template.querySelector('.slds-modal__content');
        const rect = container.getBoundingClientRect();

        this.contextNodeId = el.dataset.id;
        this.contextNodeLevel = level;
        this.contextNodeLabel = el.dataset.label;
        this.contextCreateType = 'submenu';
        this.contextParentSectionId = el.dataset.id;
        this.contextMenuX = event.clientX - rect.left;
        this.contextMenuY = event.clientY - rect.top;
        this.showContextMenu = true;
        this.showNewItemInput = false;
        this.newItemName = '';
        this._positionContextMenu();
    }

    handleDashboardHeaderContextMenu(event) {
        event.preventDefault();
        event.stopPropagation();

        const container = this.template.querySelector('.slds-modal__content');
        const rect = container.getBoundingClientRect();

        this.contextNodeId = '';
        this.contextNodeLevel = 0;
        this.contextNodeLabel = '';
        this.contextCreateType = 'menu';
        this.contextParentSectionId = '';
        this.contextMenuX = event.clientX - rect.left;
        this.contextMenuY = event.clientY - rect.top;
        this.showContextMenu = true;
        this.showNewItemInput = false;
        this.newItemName = '';
        this._positionContextMenu();
    }

    handleContextAddItem() {
        this.showNewItemInput = true;
    }

    handleNewItemNameChange(event) {
        this.newItemName = event.target.value;
    }

    async handleNewItemSave() {
        const name = this.newItemName.trim();
        if (!name) return;

        this.isTreeLoading = true;
        this.showContextMenu = false;
        this.showNewItemInput = false;

        try {
            if (this.contextCreateType === 'submenu') {
                await createNewSubmenuPage({
                    parentSectionId: this.contextParentSectionId,
                    customName: name,
                    academicYear: this.selectedAcademicYear
                });
            } else {
                await createNewMenuPage({
                    dbn: this.selectedAssignRow.dbn,
                    customName: name,
                    academicYear: this.selectedAcademicYear
                });
            }

            this.showToast('Success', `"${name}" created.`, 'success');
            await this._loadDashboardTreeForAssign(this.selectedAssignRow.dbn);
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    handleNewItemCancel() {
        this.showContextMenu = false;
        this.showNewItemInput = false;
        this.newItemName = '';
        this.contextCreateType = '';
    }

    handleDismissContextMenu() {
        this.showContextMenu = false;
        this.showNewItemInput = false;
        this.newItemName = '';
        this.contextCreateType = '';
    }

    // ── Performance bands modal ──

    async openBandsModal(row) {
        if (!row.administrationPeriodId) {
            this.showToast(
                'Error',
                'Performance bands require an administration period on this row.',
                'error'
            );
            return;
        }
        this.selectedBandsRow = row;
        this.isBandsModalOpen = true;
        this.isBandsLoading = true;
        this.editingLevelKey = null;
        this.levels = LEVEL_DEFAULTS.map(d => ({
            ...d,
            value: d.defaultValue,
            color: d.defaultColor,
            levelName: d.defaultName
        }));

        try {
            const dto = await getPerformanceBands({
                administrationPeriodId: row.administrationPeriodId
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
        this.levels = [];
        this.editingLevelKey = null;
        this.isSavingBands = false;
    }

    get bandsModalTitle() {
        if (!this.selectedBandsRow) {
            return 'Performance bands';
        }
        const period = this.selectedBandsRow.administrationPeriodName;
        const suffix = period ? ` (${period})` : '';
        return `Performance bands — ${this.selectedBandsRow.assessmentName}${suffix}`;
    }

    get hasLevel4() {
        return this.levels.some(l => l.key === '4');
    }

    get hasLevel5() {
        return this.levels.some(l => l.key === '5');
    }

    get canAddLevel() {
        return !this.hasLevel5;
    }

    get addLevelLabel() {
        return this.hasLevel5 ? '' : 'Add Level 5';
    }

    get levelsWithStyles() {
        const lastKey = this.levels.length > 0 ? this.levels[this.levels.length - 1].key : null;
        return this.levels.map(l => {
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

    _mergeLevelsFromDto(dto) {
        if (!dto) {
            return null;
        }
        const threshPresent = ['level1Below', 'level2Min', 'level3Min', 'level4Min', 'level5Min'].some(
            k => dto[k] !== undefined && dto[k] !== null
        );
        const colorPresent = ['level1Color', 'level2Color', 'level3Color', 'level4Color', 'level5Color'].some(
            k => dto[k]
        );
        const namePresent = ['level1Name', 'level2Name', 'level3Name', 'level4Name', 'level5Name'].some(
            k => dto[k]
        );
        if (!threshPresent && !colorPresent && !namePresent) {
            return null;
        }

        const merged = [];
        for (const d of LEVEL_DEFAULTS) {
            const tk = DTO_THRESH_KEYS[d.key];
            const ck = DTO_COLOR_KEYS[d.key];
            const nk = DTO_NAME_KEYS[d.key];
            const storedVal = dto[tk];
            const storedColor = dto[ck];
            const storedName = dto[nk];
            merged.push({
                ...d,
                value: storedVal !== undefined && storedVal !== null ? storedVal : d.defaultValue,
                color: storedColor || d.defaultColor,
                levelName: storedName || d.defaultName
            });
        }
        if (
            (dto.level5Min !== undefined && dto.level5Min !== null) ||
            dto.level5Color ||
            dto.level5Name
        ) {
            merged.push({
                ...LEVEL5_DEFAULT,
                value:
                    dto.level5Min !== undefined && dto.level5Min !== null
                        ? dto.level5Min
                        : LEVEL5_DEFAULT.defaultValue,
                color: dto.level5Color || LEVEL5_DEFAULT.defaultColor,
                levelName: dto.level5Name || LEVEL5_DEFAULT.defaultName
            });
        }
        return merged.sort((a, b) => a.num - b.num);
    }

    handleAddLevel() {
        if (!this.hasLevel5) {
            this.levels = [
                ...this.levels,
                {
                    ...LEVEL5_DEFAULT,
                    value: LEVEL5_DEFAULT.defaultValue,
                    color: LEVEL5_DEFAULT.defaultColor,
                    levelName: LEVEL5_DEFAULT.defaultName
                }
            ].sort((a, b) => a.num - b.num);
        }
        this._applyColorPalette();
    }

    handleRemoveLevel(event) {
        const key = event.currentTarget.dataset.level;
        this.levels = this.levels.filter(l => l.key !== key);
        this._applyColorPalette();
    }

    handleBadgeClick(event) {
        const key = event.currentTarget.dataset.level;
        if (key === '5') {
            this.handleRemoveLevel(event);
        }
    }

    handleLabelDblClick(event) {
        const key = event.currentTarget.dataset.level;
        this.editingLevelKey = key;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const input = this.template.querySelector(`lightning-input[data-edit-level="${key}"]`);
            if (input) input.focus();
        }, 50);
    }

    handleLabelBlur(event) {
        const key = event.target.dataset.editLevel;
        const newName = event.target.value;
        const def =
            LEVEL_DEFAULTS.find(d => d.key === key) ||
            (key === '5' ? LEVEL5_DEFAULT : null);
        this.levels = this.levels.map(l =>
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
        this.levels = this.levels.map(l =>
            l.key === key ? { ...l, value: raw !== '' && raw != null ? Number(raw) : null } : l
        );
    }

    handleColorChange(event) {
        const key = event.target.dataset.level;
        this.levels = this.levels.map(l =>
            l.key === key ? { ...l, color: event.target.value } : l
        );
    }

    handleHexInput(event) {
        const key = event.target.dataset.level;
        let hex = event.target.value;
        if (hex && !hex.startsWith('#')) hex = '#' + hex;
        if (/^#[0-9A-Fa-f]{6}$/.test(hex)) {
            this.levels = this.levels.map(l =>
                l.key === key ? { ...l, color: hex } : l
            );
        }
    }

    _applyColorPalette() {
        const count = this.levels.length;
        const palette = COLOR_PALETTES[count];
        if (!palette) return;
        this.levels = this.levels.map((l, index) => ({
            ...l,
            color: palette[index] || l.color
        }));
    }

    _buildBandsPayloadDto() {
        const byKey = new Map(this.levels.map(l => [l.key, l]));
        const gv = k => {
            const l = byKey.get(k);
            return l && l.value !== undefined && l.value !== null ? l.value : null;
        };
        const gc = k => {
            const l = byKey.get(k);
            return l && l.color ? l.color : null;
        };
        const gn = k => {
            const l = byKey.get(k);
            return l && l.levelName ? l.levelName : null;
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

    async handleSaveBands() {
        if (this.hasSequentialError) {
            this.showToast('Error', this.sequentialError, 'error');
            return;
        }
        this.isSavingBands = true;
        try {
            await savePerformanceBands({
                administrationPeriodId: this.selectedBandsRow.administrationPeriodId,
                bands: this._buildBandsPayloadDto()
            });
            this.showToast('Success', 'Performance bands saved.', 'success');
            this.closeBandsModal();
            await refreshApex(this.wiredRowsResult);
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        }
        this.isSavingBands = false;
    }

    // ── CSS class helpers (direct DOM for perf) ──

    _addDraggingClass() {
        const container = this.template.querySelector('.tree-container');
        if (container) container.classList.add('is-dragging');
    }

    _removeDraggingClass() {
        const container = this.template.querySelector('.tree-container');
        if (container) container.classList.remove('is-dragging');
    }

    _clearAllTimers() {
        Object.values(this._expandTimers).forEach(t => clearTimeout(t));
        this._expandTimers = {};
    }

    // ── Utilities ──

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    extractErrorMessage(error) {
        if (typeof error === 'string') {
            return error;
        }
        const body = error?.body;
        if (body) {
            if (Array.isArray(body) && body.length > 0) {
                return body.map((entry) => entry.message).filter(Boolean).join(' ');
            }
            if (body.message) {
                return body.message;
            }
            if (body.pageErrors?.length) {
                return body.pageErrors.map((entry) => entry.message).join(' ');
            }
            if (body.output?.errors?.length) {
                return body.output.errors.map((entry) => entry.message).join(' ');
            }
        }
        if (error?.message) {
            return error.message;
        }
        return 'An unexpected error occurred.';
    }

    sortData(fieldName, direction, data) {
        const mul = direction === 'asc' ? 1 : -1;
        return data.sort((a, b) => {
            const va = a[fieldName] || '';
            const vb = b[fieldName] || '';
            if (va < vb) return -1 * mul;
            if (va > vb) return 1 * mul;
            return 0;
        });
    }
}