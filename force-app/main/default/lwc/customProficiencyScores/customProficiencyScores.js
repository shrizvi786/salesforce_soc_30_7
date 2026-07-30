import { LightningElement, track } from 'lwc';
import getRecentAssessments from '@salesforce/apex/ProficiencyScoreController.getRecentAssessments';
import getExistingScore from '@salesforce/apex/ProficiencyScoreController.getExistingScore';
import saveProficiencyScore from '@salesforce/apex/ProficiencyScoreController.saveProficiencyScore';
import saveProficiencyScoresForRollupGroup from '@salesforce/apex/ProficiencyScoreController.saveProficiencyScoresForRollupGroup';
import getAssessmentIdsWithScores from '@salesforce/apex/ProficiencyScoreController.getAssessmentIdsWithScores';
import getDbnDashboardUrls from '@salesforce/apex/ProficiencyScoreController.getDbnDashboardUrls';
import createAssessmentRollupGroup from '@salesforce/apex/ProficiencyScoreController.createAssessmentRollupGroup';
import getRollupGroupsForPicker from '@salesforce/apex/ProficiencyScoreController.getRollupGroupsForPicker';
import getRollupGroupMembers from '@salesforce/apex/ProficiencyScoreController.getRollupGroupMembers';
import addAssessmentsToRollupGroup from '@salesforce/apex/ProficiencyScoreController.addAssessmentsToRollupGroup';
import removeRollupGroupMembers from '@salesforce/apex/ProficiencyScoreController.removeRollupGroupMembers';
import getDashboardTree from '@salesforce/apex/AssessmentAssignmentController.getDashboardTree';
import createNewMenuPage from '@salesforce/apex/AssessmentAssignmentController.createNewMenuPage';
import createNewSubmenuPage from '@salesforce/apex/AssessmentAssignmentController.createNewSubmenuPage';
import assignRollupGroupToDashboard from '@salesforce/apex/ProficiencyScoreController.assignRollupGroupToDashboard';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DND_EXPAND_MS = 700;

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

const COLUMNS = [
    { label: 'Assessment ID', fieldName: 'Assessment_ID__c', type: 'text', sortable: true },
    { label: 'Assessment Name', fieldName: 'Assessment_Name__c', type: 'text', wrapText: true, sortable: true },
    { label: 'DBN', fieldName: 'DBN__c', type: 'text', sortable: true },
    { label: 'Created Date', fieldName: 'Created_Date__c', type: 'date', sortable: true },
    { label: 'Last Modified Date', fieldName: 'LastModifiedDate', type: 'date', sortable: true },
    {
        label: 'Default/Custom',
        fieldName: 'defaultCustomUrl',
        type: 'url',
        sortable: true,
        initialWidth: 130,
        typeAttributes: { label: { fieldName: 'defaultCustomLabel' }, target: { fieldName: 'defaultCustomTarget' } }
    },
    {
        label: 'Dashboard Page',
        fieldName: 'dashboardPageUrl',
        type: 'url',
        sortable: true,
        typeAttributes: { label: { fieldName: 'dashboardPageLabel' }, target: '_blank' }
    },
    {
        label: 'Performance Levels Bands',
        type: 'button',
        initialWidth: 240,
        typeAttributes: { label: 'Edit', name: 'proficiency', variant: 'brand' }
    }
];

const LEVEL_DEFAULTS = [
    { key: '1', num: 1, defaultName: 'Level 1', defaultColor: '#e24b4a', defaultValue: 50 },
    { key: '2', num: 2, defaultName: 'Level 2', defaultColor: '#ef9f27', defaultValue: 50 },
    { key: '3', num: 3, defaultName: 'Level 3', defaultColor: '#639922', defaultValue: 65 },
    { key: '4', num: 4, defaultName: 'Level 4', defaultColor: '#378add', defaultValue: 85 }
];

const LEVEL5_DEFAULT = { key: '5', num: 5, defaultName: 'Level 5', defaultColor: '#378add', defaultValue: null };

const COLOR_PALETTES = {
    3: ['#e24b4a', '#ef9f27', '#639922'],
    4: ['#e24b4a', '#ef9f27', '#639922', '#378add'],
    5: ['#e24b4a', '#E89A2E', '#ef9f27', '#639922', '#378add']
};

const FIELD_MAP = {
    level1Below: 'Level_1_Below__c',
    level2Min:   'Level_2_min__c',
    level3Min:   'Level_3_min__c',
    level4Min:   'Level_4_min__c',
    level5Min:   'Level_5_min__c',
    level1Color: 'Level_1_color__c',
    level2Color: 'Level_2_color__c',
    level3Color: 'Level_3_color__c',
    level4Color: 'Level_4_color__c',
    level5Color: 'Level_5_color__c',
    level1Name:  'Level_1_Name__c',
    level2Name:  'Level_2_Name__c',
    level3Name:  'Level_3_Name__c',
    level4Name:  'Level_4_Name__c',
    level5Name:  'Level_5_Name__c'
};

const PAGE_SIZE_OPTIONS = [
    { label: '10', value: '10' },
    { label: '25', value: '25' },
    { label: '50', value: '50' },
    { label: '100', value: '100' }
];

const MEMBER_COLUMNS = [
    { label: 'Assessment ID', fieldName: 'Assessment_ID__c', type: 'text', sortable: true },
    { label: 'Assessment Name', fieldName: 'Assessment_Name__c', type: 'text', wrapText: true, sortable: true },
    { label: 'DBN', fieldName: 'DBN__c', type: 'text', sortable: true },
    { label: 'Assessment date', fieldName: 'Assessment_Date__c', type: 'date', sortable: true }
];

function valueFieldKey(levelKey) {
    return levelKey === '1' ? 'level1Below' : `level${levelKey}Min`;
}
function colorFieldKey(levelKey) {
    return `level${levelKey}Color`;
}
function nameFieldKey(levelKey) {
    return `level${levelKey}Name`;
}
function stripDbnFromGroupName(name) {
    if (!name) {
        return '';
    }
    const trimmed = name.trim();
    const sep = ' - ';
    const idx = trimmed.indexOf(sep);
    if (idx > 0 && idx <= 12) {
        const remainder = trimmed.substring(idx + sep.length).trim();
        if (remainder) {
            return remainder;
        }
    }
    return trimmed;
}

function hexToRgba(hex, alpha) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

export default class CustomProficiencyScores extends LightningElement {
    columns = COLUMNS;
    memberColumns = MEMBER_COLUMNS;
    pageSizeOptions = PAGE_SIZE_OPTIONS;

    /**
     * lightning-datatable only shows the selection column when max-row-selection
     * is set to a positive number (otherwise the checkbox column stays hidden).
     */
    maxRowSelection = 2000;

    allAssessments = [];
    isLoading = true;
    sortedBy = 'CreatedDate';
    sortDirection = 'desc';

    searchTerm = '';
    currentPage = 1;
    pageSize = 100;

    isModalOpen = false;
    isGroupBandsModalOpen = false;
    isModalLoading = false;
    isGroupBandsModalLoading = false;
    isSaving = false;
    isGroupBandsSaving = false;
    selectedAssessment = null;

    /** Row IDs (key-field) for lightning-datatable selection */
    selectedRowIds = [];
    datatableRenderKey = 0;

    isGroupModalOpen = false;
    groupNameInput = '';
    isCreatingRollupGroup = false;

    /** Rollup group picker + members (Pattern B) */
    rollupGroupOptions = [];
    selectedRollupGroupId = '';
    groupMemberRows = [];
    selectedMemberRowIds = [];
    memberDatatableKey = 0;
    isLoadingMembers = false;
    isRollupGroupActionPending = false;
    rollupGroupSearchTerm = '';
    /** Group list is hidden until the user focuses the search field */
    isRollupGroupListOpen = false;

    isDashboardAssignModalOpen = false;
    isDashboardModalLoading = false;
    isDashboardAssigning = false;
    selectedAcademicYear = DEFAULT_ACADEMIC_YEAR;
    academicYearOptions = ACADEMIC_YEAR_OPTIONS;
    /** @track Drag-and-drop dashboard tree (see assessmentAssignment) */
    @track dashTreeData = [];
    dashTreeDbn = '';
    isDashPlaced = false;
    dndIsDragging = false;
    dndType = '';
    dndScrollRafId;
    dndExpandTimers = {};
    dndAutoExpandIds = new Map();
    showDashCtx = false;
    dashCtxX = 0;
    dashCtxY = 0;
    dashCtxNodeId = '';
    dashCtxType = '';
    dashCtxParentSectionId = '';
    showDashCtxInput = false;
    dashNewItemName = '';

    /** After a valid drop zone hit: confirm which assessments appear under the menu / sub-menu */
    dashDropConfirmOpen = false;
    dashDropPending = null;
    dashDropConfirmRows = [];

    existingRecordId = null;
    existingRecord = null;
    editingLevelKey = null;

    @track levels = [];

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        try {
            const [assessments, scoreMap, dbnUrlMap, rollupGroups] = await Promise.all([
                getRecentAssessments(),
                getAssessmentIdsWithScores(),
                getDbnDashboardUrls(),
                getRollupGroupsForPicker()
            ]);
            this._applyRollupGroupOptions(rollupGroups);
            const sorted = this._sortData(this.sortedBy, this.sortDirection, [...assessments]);
            this.allAssessments = sorted.map(a => {
                const scoreRecordId = scoreMap[a.Id];
                const hasScore = !!scoreRecordId;
                const dashUrl = a.DBN__c ? (dbnUrlMap[a.DBN__c] || '') : '';
                return {
                    ...a,
                    hasCustomScore: hasScore,
                    defaultCustomLabel: hasScore ? 'Custom' : 'Default',
                    defaultCustomUrl: hasScore
                        ? `/lightning/r/Custom_Dashboard_Proficiency_scores__c/${scoreRecordId}/view`
                        : '#',
                    defaultCustomTarget: hasScore ? '_blank' : '_self',
                    dashboardPageUrl: dashUrl || '',
                    dashboardPageLabel: dashUrl ? 'View Dashboard \u2197' : ''
                };
            });
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
        }
        this.isLoading = false;
        this._clearTableSelection();
        await this._reloadMembersIfGroupSelected();
    }

    // ── Computed: search + pagination ──

    get filteredAssessments() {
        if (!this.searchTerm) return this.allAssessments;
        const term = this.searchTerm.toLowerCase();
        return this.allAssessments.filter(a =>
            (a.Assessment_ID__c || '').toLowerCase().includes(term) ||
            (a.Assessment_Name__c || '').toLowerCase().includes(term) ||
            (a.DBN__c || '').toLowerCase().includes(term)
        );
    }

    get paginatedAssessments() {
        const start = (this.currentPage - 1) * this.pageSize;
        return this.filteredAssessments.slice(start, start + this.pageSize);
    }

    get totalPages() {
        const total = this.filteredAssessments.length;
        return total === 0 ? 1 : Math.ceil(total / this.pageSize);
    }

    get hasAssessments() {
        return this.allAssessments && this.allAssessments.length > 0;
    }

    get showingRange() {
        const filtered = this.filteredAssessments;
        if (filtered.length === 0) return 'No results';
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

    get isGroupButtonDisabled() {
        return !this.selectedRowIds || this.selectedRowIds.length < 2;
    }

    get groupModalTitle() {
        const n = this.selectedRowIds ? this.selectedRowIds.length : 0;
        return `Create assessment group (${n} selected)`;
    }

    get isCreateGroupDisabled() {
        if (this.isCreatingRollupGroup) {
            return true;
        }
        return !this.groupNameInput || !this.groupNameInput.trim();
    }

    get hasRollupGroupSelected() {
        return !!this.selectedRollupGroupId;
    }

    get isAddToRollupGroupDisabled() {
        return (
            this.isRollupGroupActionPending ||
            !this.hasRollupGroupSelected ||
            !this.selectedRowIds ||
            this.selectedRowIds.length < 1
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

    get memberMaxRowSelection() {
        return 500;
    }

    get filteredRollupGroupRows() {
        const q = (this.rollupGroupSearchTerm || '').trim().toLowerCase();
        const base = this.rollupGroupOptions || [];
        const filtered = !q
            ? base
            : base.filter(o => (o.label || '').toLowerCase().includes(q));
        return filtered.map(o => ({
            label: o.label,
            value: o.value,
            rowClass:
                o.value === this.selectedRollupGroupId
                    ? 'group-picker-row is-selected'
                    : 'group-picker-row'
        }));
    }

    get selectedRollupGroupName() {
        const g = (this.rollupGroupOptions || []).find(o => o.value === this.selectedRollupGroupId);
        return g && g.label ? g.label : 'Selected group';
    }

    get selectedRollupGroupDisplayName() {
        const g = (this.rollupGroupOptions || []).find(o => o.value === this.selectedRollupGroupId);
        const storedName = g && g.label ? g.label.split(' · ')[0] : 'Selected group';
        return stripDbnFromGroupName(storedName);
    }

    get isGroupBandsButtonDisabled() {
        return (
            !this.hasRollupGroupSelected ||
            !this.groupMemberRows ||
            this.groupMemberRows.length === 0 ||
            this.isRollupGroupActionPending
        );
    }

    get groupBandsModalTitle() {
        return `Performance Levels Bands — ${this.selectedRollupGroupDisplayName} (all members)`;
    }

    get isGroupBandsSaveDisabled() {
        return this.isGroupBandsSaving || this.hasSequentialError;
    }

    get hasDashTree() {
        return this.dashTreeData && this.dashTreeData.length > 0;
    }

    get dndGroupCardClass() {
        return this.dndIsDragging && this.dndType === 'group' ? 'drag-card drag-card-dragging' : 'drag-card';
    }

    get dashFlatTree() {
        const out = [];
        this._dndBuildFlat(this.dashTreeData, 1, this.dashTreeDbn, 'top', out);
        return out;
    }

    get dndCtxInputPlaceholder() {
        return this.dashCtxType === 'submenu' ? 'Enter sub-menu name' : 'Enter menu name';
    }

    get dndCtxLabel() {
        return this.dashCtxType === 'submenu' ? 'Create new sub-menu' : 'Create new menu';
    }

    get isDndNewItemSaveDisabled() {
        return !this.dashNewItemName || !this.dashNewItemName.trim();
    }

    get isAssignToDashboardDisabled() {
        return (
            !this.hasRollupGroupSelected ||
            !this.groupMemberRows ||
            this.groupMemberRows.length === 0 ||
            this.isRollupGroupActionPending
        );
    }

    get rollupGroupPickerEmpty() {
        return !this.filteredRollupGroupRows || this.filteredRollupGroupRows.length === 0;
    }

    get rollupGroupDropdownEmpty() {
        return this.isRollupGroupListOpen && this.rollupGroupPickerEmpty;
    }

    get modalTitle() {
        return this.selectedAssessment
            ? `Performance Levels Bands \u2014 ${this.selectedAssessment.Assessment_Name__c}`
            : 'Performance Levels Bands';
    }

    // ── Level visibility computed ──

    get hasLevel4() {
        return this.levels.some(l => l.key === '4');
    }

    get hasLevel5() {
        return this.levels.some(l => l.key === '5');
    }

    get canAddLevel() {
        return !this.hasLevel4 || !this.hasLevel5;
    }

    get addLevelLabel() {
        if (!this.hasLevel4) return 'Add Level 4';
        if (!this.hasLevel5) return 'Add Level 5';
        return '';
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
                canRemove: l.key === '4' || l.key === '5',
                isEditing: l.key === this.editingLevelKey
            };
        });
    }

    // ── Sequential validation ──

    get sequentialError() {
        for (let i = 1; i < this.levels.length; i++) {
            const prev = this.levels[i - 1].value;
            const curr = this.levels[i].value;
            if (prev != null && curr != null && curr < prev) {
                return `Each level's value must be greater than or equal to the previous level.`;
            }
        }
        return '';
    }

    get hasSequentialError() {
        return this.sequentialError !== '';
    }

    get isSaveDisabled() {
        return this.isSaving || this.hasSequentialError;
    }

    // ── Search ──

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.currentPage = 1;
        this._clearTableSelection();
    }

    handleRowSelection(event) {
        const rows = event.detail.selectedRows || [];
        this.selectedRowIds = rows.map(r => r.Id);
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
        this.isCreatingRollupGroup = true;
        try {
            const newGroupId = await createAssessmentRollupGroup({
                groupName: this.groupNameInput.trim(),
                recentlyAddedAssessmentIds: this.selectedRowIds
            });
            this._toast(
                'Success',
                'Group created. Members may take a moment to appear — use Refresh if needed.',
                'success'
            );
            this.closeGroupModal();
            this._clearTableSelection();
            if (newGroupId) {
                this.selectedRollupGroupId = newGroupId;
            }
            await this.loadData();
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
        }
        this.isCreatingRollupGroup = false;
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
        const rt = event.relatedTarget;
        if (panel && rt && typeof rt === 'object' && panel.contains(rt)) {
            return;
        }
        // Defer: relatedTarget is sometimes null across shadow boundaries; list clicks need a tick.
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
        const id = event.currentTarget.dataset.id;
        if (!id) {
            return;
        }
        const previous = this.selectedRollupGroupId;
        this.selectedRollupGroupId = id;
        this.isRollupGroupListOpen = false;
        if (id !== previous) {
            this.memberDatatableKey += 1;
        }
        await this._reloadMembersIfGroupSelected();
    }

    async handleRefreshRollupGroups() {
        try {
            const rollupGroups = await getRollupGroupsForPicker();
            this._applyRollupGroupOptions(rollupGroups);
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
        }
    }

    handleMemberRowSelection(event) {
        const rows = event.detail.selectedRows || [];
        this.selectedMemberRowIds = rows.map(r => r.Id);
    }

    async handleRefreshMembers() {
        this.memberDatatableKey += 1;
        await this._reloadMembersIfGroupSelected();
    }

    async openDashboardAssignModal() {
        if (this.isAssignToDashboardDisabled) {
            return;
        }
        const dbn = this._getDbnForSelectedRollupGroup();
        if (!dbn) {
            this._toast('Error', 'Could not determine DBN from group members.', 'error');
            return;
        }
        const rows = this.groupMemberRows || [];
        const firstDbn = rows.length ? rows[0].DBN__c : '';
        if (firstDbn && rows.some(r => r.DBN__c !== firstDbn)) {
            this._toast(
                'Warning',
                'This group lists more than one DBN; the dashboard is loaded using the first member’s DBN.',
                'warning'
            );
        }
        this._dndResetUiState();
        this.selectedAcademicYear = DEFAULT_ACADEMIC_YEAR;
        this.isDashboardAssignModalOpen = true;
        this.isDashboardModalLoading = true;
        this.dashTreeDbn = dbn;
        this.isDashPlaced = false;
        try {
            await this._loadDashboardTree();
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
            this.closeDashboardAssignModal();
            return;
        } finally {
            this.isDashboardModalLoading = false;
        }
    }

    closeDashboardAssignModal() {
        this.isDashboardAssignModalOpen = false;
        this.isDashboardModalLoading = false;
        this.isDashboardAssigning = false;
        this.selectedAcademicYear = DEFAULT_ACADEMIC_YEAR;
        this._dndResetUiState();
    }

    async handleAcademicYearChange(event) {
        this.selectedAcademicYear = event.detail.value;
        if (!this.dashTreeDbn) {
            return;
        }
        this.isDashboardModalLoading = true;
        this.dndAutoExpandIds = new Map();
        try {
            await this._loadDashboardTree();
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
        } finally {
            this.isDashboardModalLoading = false;
        }
    }

    async _loadDashboardTree() {
        const tree = await getDashboardTree({
            dbn: this.dashTreeDbn,
            academicYear: this.selectedAcademicYear
        });
        this.dashTreeData = this._dndInitTree(tree);
    }

    _dndResetUiState() {
        this.dashTreeData = [];
        this.dashTreeDbn = '';
        this.isDashPlaced = false;
        this.dndIsDragging = false;
        this.dndType = '';
        this.showDashCtx = false;
        this.showDashCtxInput = false;
        this.dashNewItemName = '';
        this.dashCtxType = '';
        this.dndAutoExpandIds = new Map();
        this.dndExpandTimers = {};
        this._dndStopScroll();
        this._dndClearTimers();
        this._closeDashDropConfirm();
        const t = this.template;
        if (t) {
            t.querySelectorAll('.drop-zone-active').forEach(el => el.classList && el.classList.remove('drop-zone-active'));
        }
    }

    _closeDashDropConfirm() {
        this.dashDropConfirmOpen = false;
        this.dashDropPending = null;
        this.dashDropConfirmRows = [];
    }

    get dashDropConfirmHasSelection() {
        return (this.dashDropConfirmRows || []).some(r => r.checked);
    }

    get isDashDropConfirmSaveDisabled() {
        return this.isDashboardAssigning || !this.dashDropConfirmHasSelection;
    }

    handleDashDropConfirmToggle(event) {
        const rowKey = event.currentTarget.dataset.rowKey;
        const checked = event.detail.checked === true;
        this.dashDropConfirmRows = (this.dashDropConfirmRows || []).map(r =>
            r.rowKey === rowKey ? { ...r, checked } : r
        );
    }

    handleDashDropConfirmCancel() {
        this._closeDashDropConfirm();
    }

    handleDashDropConfirmBackdrop() {
        if (!this.isDashboardAssigning) {
            this._closeDashDropConfirm();
        }
    }

    handleDashDropConfirmPanelClick(event) {
        event.stopPropagation();
    }

    async handleDashDropConfirmSave() {
        if (!this.dashDropConfirmHasSelection || !this.dashDropPending) {
            this._toast('Selection required', 'Choose at least one assessment to place on the dashboard.', 'error');
            return;
        }
        const ids = this.dashDropConfirmRows.filter(r => r.checked).map(r => r.assessmentId).filter(Boolean);
        if (!ids.length) {
            this._toast('Selection required', 'Choose at least one assessment to place on the dashboard.', 'error');
            return;
        }
        const pending = this.dashDropPending;
        this.isDashboardAssigning = true;
        try {
            await assignRollupGroupToDashboard({
                rollupGroupId: this.selectedRollupGroupId,
                placementLevel: pending.placementLevel,
                parentMenuSectionId: pending.parentMenuSectionId || null,
                dbn: pending.dbn,
                includedAssessmentIds: ids,
                academicYear: this.selectedAcademicYear
            });
            this._closeDashDropConfirm();
            this._toast('Success', 'Rollup group was added to the dashboard.', 'success');
            this.isDashPlaced = true;
            this.memberDatatableKey += 1;
            await this._reloadMembersIfGroupSelected();
            await this.handleRefreshRollupGroups();
            await this._loadDashboardTree();
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
        } finally {
            this.isDashboardAssigning = false;
        }
    }

    handleDndGroupDragStart(event) {
        this.dndIsDragging = true;
        this.dndType = 'group';
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', 'rollup-group');
        const wrap = this.template.querySelector('.rollup-dnd-tree-wrap .tree-container');
        if (wrap) wrap.classList.add('is-dragging');
    }

    handleDndDragEnd() {
        this.dndIsDragging = false;
        this.dndType = '';
        this.dndAutoExpandIds = new Map();
        this.dndExpandTimers = {};
        const wrap = this.template.querySelector('.rollup-dnd-tree-wrap .tree-container');
        if (wrap) {
            wrap.classList.remove('is-dragging');
        }
        this._dndStopScroll();
        this._dndClearTimers();
    }

    handleDndTreeDragOver(event) {
        event.preventDefault();
        if (!this.dndIsDragging) {
            return;
        }
        const edge = 60;
        const maxSpeed = 14;
        const mouseY = event.clientY;
        const treeEl = this.template.querySelector('.rollup-dnd-tree-wrap .tree-container');
        const modalEl = this.template.querySelector('.rollup-dnd-body');
        let tDelta = 0;
        let mDelta = 0;
        if (treeEl) {
            const r = treeEl.getBoundingClientRect();
            if (mouseY < r.top + edge && mouseY >= r.top) {
                tDelta = -maxSpeed * ((r.top + edge - mouseY) / edge);
            } else if (mouseY > r.bottom - edge && mouseY <= r.bottom) {
                tDelta = maxSpeed * ((mouseY - (r.bottom - edge)) / edge);
            }
        }
        if (modalEl) {
            const r = modalEl.getBoundingClientRect();
            if (mouseY < r.top + edge && mouseY >= r.top) {
                mDelta = -maxSpeed * ((r.top + edge - mouseY) / edge);
            } else if (mouseY > r.bottom - edge && mouseY <= r.bottom) {
                mDelta = maxSpeed * ((mouseY - (r.bottom - edge)) / edge);
            }
        }
        if (tDelta !== 0 || mDelta !== 0) {
            this._dndStartScroll(treeEl, tDelta, modalEl, mDelta);
        } else {
            this._dndStopScroll();
        }
    }

    _dndStartScroll(treeEl, t, modalEl, m) {
        this._dndStopScroll();
        const step = () => {
            if (treeEl && t) treeEl.scrollTop += t;
            if (modalEl && m) modalEl.scrollTop += m;
            this.dndScrollRafId = requestAnimationFrame(step);
        };
        this.dndScrollRafId = requestAnimationFrame(step);
    }

    _dndStopScroll() {
        if (this.dndScrollRafId) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            cancelAnimationFrame(this.dndScrollRafId);
            this.dndScrollRafId = null;
        }
    }

    _dndClearTimers() {
        if (this.dndExpandTimers) {
            Object.values(this.dndExpandTimers).forEach(t => clearTimeout(t));
        }
        this.dndExpandTimers = {};
    }

    handleDndDropOver(event) {
        event.preventDefault();
        // eslint-disable-next-line no-param-reassign
        event.dataTransfer.dropEffect = 'move';
    }

    handleDndDropEnter(event) {
        event.preventDefault();
        event.currentTarget.classList.add('drop-zone-active');
    }

    handleDndDropLeave(event) {
        event.currentTarget.classList.remove('drop-zone-active');
    }

    async handleDndDropOnZone(event) {
        event.preventDefault();
        const wasGroup = this.dndType === 'group';
        event.currentTarget.classList.remove('drop-zone-active');
        this._dndStopScroll();
        const wrap = this.template.querySelector('.rollup-dnd-tree-wrap .tree-container');
        if (wrap) {
            wrap.classList.remove('is-dragging');
        }
        this._dndClearTimers();
        this.dndIsDragging = false;
        this.dndType = '';
        if (!wasGroup) {
            return;
        }

        const tLevel = event.currentTarget.dataset.targetLevel || '';
        const parentId = event.currentTarget.dataset.parentId;
        if (tLevel === 'level2') {
            this._toast(
                'Cannot place here',
                'Drop the group on the top-level list or into a main menu, not on a sub-menu row.',
                'error'
            );
            return;
        }
        const dbn = this._getDbnForSelectedRollupGroup();
        if (!dbn) {
            this._toast('Error', 'Could not determine DBN from group members.', 'error');
            return;
        }
        if (tLevel !== 'top' && !parentId) {
            this._toast('Error', 'No parent section for placement.', 'error');
            return;
        }

        try {
            await this._reloadMembersIfGroupSelected({ skipLoadingFlag: true });
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
            return;
        }

        const memberRows = this.groupMemberRows || [];
        if (!memberRows.length) {
            this._toast(
                'No assessments',
                'This group has no assessments yet; add assessments before assigning to the dashboard.',
                'error'
            );
            return;
        }
        const missingAssessmentId = memberRows.some(
            m => m.Assessment_ID__c == null || !String(m.Assessment_ID__c).trim()
        );
        if (missingAssessmentId) {
            this._toast(
                'Missing assessment ID',
                'Every group member must have an assessment ID before you can place the group on the dashboard.',
                'error'
            );
            return;
        }

        this.dashDropPending = {
            placementLevel: tLevel === 'top' ? 'top' : 'level1',
            parentMenuSectionId: tLevel === 'top' ? null : parentId,
            dbn
        };
        this.dashDropConfirmRows = memberRows.map((m, idx) => {
            const rawId = m.Assessment_ID__c != null ? String(m.Assessment_ID__c).trim() : '';
            const rowKey = m.Id || `row-${idx}-${rawId}`;
            const label =
                m.Assessment_Name__c && String(m.Assessment_Name__c).trim()
                    ? String(m.Assessment_Name__c).trim()
                    : rawId || 'Assessment';
            return {
                rowKey,
                assessmentId: rawId,
                label,
                checked: true
            };
        });
        this.dashDropConfirmOpen = true;
    }

    handleDndNodeEnter(event) {
        event.preventDefault();
        const nodeId = event.currentTarget.dataset.id;
        if (!nodeId || !this.dndIsDragging) {
            return;
        }
        const node = this._dndFindNode(this.dashTreeData, nodeId);
        if (!node) {
            return;
        }
        const nodeLevel = node.level;
        let updated = this.dashTreeData;
        const toRemove = [];
        for (const [eid, elv] of this.dndAutoExpandIds) {
            if (elv >= nodeLevel && eid !== nodeId) {
                updated = this._dndCollapseNode(updated, eid);
                toRemove.push(eid);
            }
        }
        toRemove.forEach(x => this.dndAutoExpandIds.delete(x));
        this.dashTreeData = updated;
        Object.keys(this.dndExpandTimers).forEach(tid => {
            if (tid !== nodeId) {
                clearTimeout(this.dndExpandTimers[tid]);
                delete this.dndExpandTimers[tid];
            }
        });
        if (node.nodeType === 'Menu' && !node.expanded) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.dndExpandTimers[nodeId] = setTimeout(() => {
                this.dashTreeData = this._dndExpandNode(this.dashTreeData, nodeId);
                this.dndAutoExpandIds.set(nodeId, nodeLevel);
                delete this.dndExpandTimers[nodeId];
            }, DND_EXPAND_MS);
        }
    }

    handleDndNodeLeave(event) {
        const id = event.currentTarget.dataset.id;
        if (id && this.dndExpandTimers[id]) {
            clearTimeout(this.dndExpandTimers[id]);
            delete this.dndExpandTimers[id];
        }
    }

    _dndInitTree(nodes) {
        if (!nodes) return [];
        return nodes.map(n => ({
            ...n,
            expanded: false,
            children: n.children ? this._dndInitTree(n.children) : []
        }));
    }

    _dndToggleNode(nodes, targetId) {
        return nodes.map(n => {
            if (n.id === targetId) {
                return { ...n, expanded: !n.expanded };
            }
            if (n.children && n.children.length) {
                return { ...n, children: this._dndToggleNode(n.children, targetId) };
            }
            return n;
        });
    }

    _dndExpandNode(nodes, targetId) {
        return nodes.map(n => {
            if (n.id === targetId) {
                return { ...n, expanded: true };
            }
            if (n.children && n.children.length) {
                return { ...n, children: this._dndExpandNode(n.children, targetId) };
            }
            return n;
        });
    }

    _dndCollapseNode(nodes, targetId) {
        return nodes.map(n => {
            if (n.id === targetId) {
                return { ...n, expanded: false };
            }
            if (n.children && n.children.length) {
                return { ...n, children: this._dndCollapseNode(n.children, targetId) };
            }
            return n;
        });
    }

    _dndFindNode(nodes, id) {
        for (const n of nodes) {
            if (n.id === id) {
                return n;
            }
            if (n.children) {
                const f = this._dndFindNode(n.children, id);
                if (f) {
                    return f;
                }
            }
        }
        return null;
    }

    _dndMakeDz(key, indent, parentId, targetLevel, prevSort, nextSort, isEmpty) {
        let c = isEmpty ? 'drop-zone drop-zone-empty' : 'drop-zone';
        if (indent > 0) c += ` indent-${indent}`;
        return {
            key,
            isDropZone: true,
            isNode: false,
            parentId,
            targetLevel,
            prevSort: String(prevSort),
            nextSort: String(nextSort),
            isEmpty,
            dropZoneClass: c
        };
    }

    _dndBuildFlat(nodes, indent, parentId, targetLevel, result) {
        if (!nodes || nodes.length === 0) {
            result.push(this._dndMakeDz('dz-e-' + parentId, indent, parentId, targetLevel, 0, 1, true));
            return;
        }
        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];
            const prevSort = i > 0 ? nodes[i - 1].sortOrder : 0;
            result.push(
                this._dndMakeDz('dz-b-' + node.id, indent, parentId, targetLevel, prevSort, node.sortOrder, false)
            );
            const isMenu = node.nodeType === 'Menu';
            const exp = node.expanded === true;
            result.push({
                key: node.id,
                isDropZone: false,
                isNode: true,
                id: node.id,
                label: node.label,
                isMenu,
                level: node.level,
                isMenuStr: isMenu ? 'true' : 'false',
                expandIcon: exp ? 'utility:chevrondown' : 'utility:chevronright',
                nodeClass:
                    'tree-node' +
                    (indent > 0 ? ` indent-${indent}` : '') +
                    (isMenu ? ' tree-node-folder' : '') +
                    (node.isAssessment === true ? ' tree-node-assessment' : ''),
                labelClass: 'node-label' + (isMenu ? ' folder-label' : '')
            });
            if (isMenu && exp) {
                const childLevel = targetLevel === 'top' ? 'level1' : 'level2';
                if (node.children && node.children.length) {
                    this._dndBuildFlat(node.children, indent + 1, node.id, childLevel, result);
                }
                const lastC =
                    node.children && node.children.length
                        ? node.children[node.children.length - 1]
                        : null;
                const endPrev = lastC ? lastC.sortOrder : 0;
                result.push(
                    this._dndMakeDz('dz-e-' + node.id, indent + 1, node.id, childLevel, endPrev, endPrev + 1, !lastC)
                );
            }
        }
        if (targetLevel === 'top' && nodes.length) {
            const last = nodes[nodes.length - 1];
            result.push(
                this._dndMakeDz('dz-r', 1, parentId, targetLevel, last.sortOrder, last.sortOrder + 1, false)
            );
        }
    }

    handleDndToggleExpand(event) {
        event.stopPropagation();
        const id = event.currentTarget.dataset.id;
        this.dashTreeData = this._dndToggleNode(this.dashTreeData, id);
    }

    _positionRollupCtx() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        Promise.resolve().then(() => {
            const menu = this.template.querySelector('.rollup-dnd-body .ctx-menu');
            if (menu) {
                // eslint-disable-next-line no-param-reassign
                menu.style.left = `${this.dashCtxX}px`;
                // eslint-disable-next-line no-param-reassign
                menu.style.top = `${this.dashCtxY}px`;
            }
        });
    }

    handleDashHeaderCtx(event) {
        event.preventDefault();
        event.stopPropagation();
        const container = this.template.querySelector('.rollup-dnd-body');
        if (!container) return;
        const rect = container.getBoundingClientRect();
        this.dashCtxType = 'menu';
        this.dashCtxParentSectionId = '';
        this.dashCtxNodeId = '';
        this.dashCtxX = event.clientX - rect.left;
        this.dashCtxY = event.clientY - rect.top;
        this.showDashCtx = true;
        this.showDashCtxInput = false;
        this.dashNewItemName = '';
        this._positionRollupCtx();
    }

    handleDndTreeItemCtx(event) {
        event.preventDefault();
        event.stopPropagation();
        const level = parseInt(event.currentTarget.dataset.level, 10);
        const isMenu = event.currentTarget.dataset.isMenu === 'true';
        if (level !== 1 || !isMenu) return;
        const container = this.template.querySelector('.rollup-dnd-body');
        if (!container) return;
        const rect = container.getBoundingClientRect();
        this.dashCtxType = 'submenu';
        this.dashCtxParentSectionId = event.currentTarget.dataset.id;
        this.dashCtxNodeId = event.currentTarget.dataset.id;
        this.dashCtxX = event.clientX - rect.left;
        this.dashCtxY = event.clientY - rect.top;
        this.showDashCtx = true;
        this.showDashCtxInput = false;
        this.dashNewItemName = '';
        this._positionRollupCtx();
    }

    handleDndCtxAdd() {
        this.showDashCtxInput = true;
    }

    handleDndNewName(event) {
        this.dashNewItemName = event.target.value;
    }

    handleDndNewCancel() {
        this.showDashCtx = false;
        this.showDashCtxInput = false;
        this.dashNewItemName = '';
        this.dashCtxType = '';
    }

    handleDndCtxBackdrop() {
        this.handleDndNewCancel();
    }

    async handleDndNewSave() {
        const name = (this.dashNewItemName || '').trim();
        if (!name) return;
        this.isDashboardModalLoading = true;
        this.showDashCtx = false;
        this.showDashCtxInput = false;
        const dbn = this.dashTreeDbn;
        try {
            if (this.dashCtxType === 'submenu' && this.dashCtxParentSectionId) {
                await createNewSubmenuPage({
                    parentSectionId: this.dashCtxParentSectionId,
                    customName: name,
                    academicYear: this.selectedAcademicYear
                });
            } else {
                await createNewMenuPage({
                    dbn,
                    customName: name,
                    academicYear: this.selectedAcademicYear
                });
            }
            this._toast('Success', `"${name}" was created.`, 'success');
            await this._loadDashboardTree();
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
        } finally {
            this.isDashboardModalLoading = false;
        }
    }

    _getDbnForSelectedRollupGroup() {
        const rows = this.groupMemberRows || [];
        if (!rows.length) {
            return '';
        }
        return rows[0].DBN__c || '';
    }

    async handleAddToRollupGroup() {
        if (this.isAddToRollupGroupDisabled) {
            return;
        }
        this.isRollupGroupActionPending = true;
        try {
            const result = await addAssessmentsToRollupGroup({
                groupId: this.selectedRollupGroupId,
                recentlyAddedAssessmentIds: this.selectedRowIds
            });
            const added = result?.addedCount ?? 0;
            const skipped = result?.skippedDuplicateCount ?? 0;
            let msg = `${added} assessment${added === 1 ? '' : 's'} added to the group.`;
            if (skipped > 0) {
                msg += ` ${skipped} skipped (already in group).`;
            }
            this._toast('Success', msg, 'success');
            this._clearTableSelection();
            this.memberDatatableKey += 1;
            await this._reloadMembersIfGroupSelected();
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
        }
        this.isRollupGroupActionPending = false;
    }

    async handleRemoveFromRollupGroup() {
        if (this.isRemoveFromRollupGroupDisabled) {
            return;
        }
        this.isRollupGroupActionPending = true;
        try {
            await removeRollupGroupMembers({
                groupId: this.selectedRollupGroupId,
                rollupAssessmentRecordIds: this.selectedMemberRowIds
            });
            this._toast('Success', 'Selected assessments were removed from the group.', 'success');
            this._clearMemberSelection();
            this.memberDatatableKey += 1;
            await this._reloadMembersIfGroupSelected();
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
        }
        this.isRollupGroupActionPending = false;
    }

    _applyRollupGroupOptions(rollupGroups) {
        const rows = rollupGroups || [];
        this.rollupGroupOptions = rows.map(r => ({
            label: r.label,
            value: r.value
        }));
        if (
            this.selectedRollupGroupId &&
            !this.rollupGroupOptions.some(o => o.value === this.selectedRollupGroupId)
        ) {
            this.selectedRollupGroupId = '';
            this.groupMemberRows = [];
            this._clearMemberSelection();
        }
    }

    async _reloadMembersIfGroupSelected(options = {}) {
        const skipLoadingFlag = options.skipLoadingFlag === true;
        if (!this.selectedRollupGroupId) {
            this.groupMemberRows = [];
            this.isLoadingMembers = false;
            return;
        }
        if (!skipLoadingFlag) {
            this.isLoadingMembers = true;
        }
        try {
            const rows = await getRollupGroupMembers({ groupId: this.selectedRollupGroupId });
            this.groupMemberRows = rows || [];
        } catch (error) {
            this.groupMemberRows = [];
            this._toast('Error', this._errMsg(error), 'error');
        }
        this._clearMemberSelection();
        if (!skipLoadingFlag) {
            this.isLoadingMembers = false;
        }
    }

    _clearMemberSelection() {
        this.selectedMemberRowIds = [];
        this.memberDatatableKey += 1;
    }

    _clearTableSelection() {
        this.selectedRowIds = [];
        this.datatableRenderKey += 1;
    }

    // ── Pagination ──

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value, 10);
        this.currentPage = 1;
        this._clearTableSelection();
    }

    handlePrevPage() {
        if (this.currentPage > 1) this.currentPage--;
        this._clearTableSelection();
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) this.currentPage++;
        this._clearTableSelection();
    }

    // ── Sorting ──

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortDirection = sortDirection;
        this.allAssessments = this._sortData(fieldName, sortDirection, [...this.allAssessments]);
        this.currentPage = 1;
        this._clearTableSelection();
    }

    // ── Row action ──

    handleRowAction(event) {
        if (event.detail.action.name === 'proficiency') {
            this._openModal(event.detail.row);
        }
    }

    // ── Modal ──

    async _openModal(row) {
        this.selectedAssessment = row;
        this.isModalOpen = true;
        this.isModalLoading = true;
        this.existingRecordId = null;
        this.existingRecord = null;
        this.editingLevelKey = null;

        this.levels = LEVEL_DEFAULTS.map(d => ({
            ...d, value: d.defaultValue, color: d.defaultColor, levelName: d.defaultName
        }));

        try {
            const existing = await getExistingScore({
                assessmentId: row.Id,
                dbn: row.DBN__c
            });
            if (existing) {
                this.existingRecordId = existing.Id;
                this.existingRecord = existing;

                this.levels = this.levels.map(l => {
                    const sfVal  = existing[FIELD_MAP[valueFieldKey(l.key)]];
                    const sfCol  = existing[FIELD_MAP[colorFieldKey(l.key)]];
                    const sfName = existing[FIELD_MAP[nameFieldKey(l.key)]];
                    return {
                        ...l,
                        value: sfVal != null ? sfVal : l.value,
                        color: sfCol || l.defaultColor,
                        levelName: sfName || l.defaultName
                    };
                });
            }
        } catch (e) {
            this._toast('Error', 'Failed to load existing scores.', 'error');
        }
        this.isModalLoading = false;
    }

    closeModal() {
        this.isModalOpen = false;
        this.selectedAssessment = null;
        this.existingRecord = null;
        this.editingLevelKey = null;
        this.levels = [];
    }

    async openGroupBandsModal() {
        if (this.isGroupBandsButtonDisabled) {
            return;
        }
        this.isGroupBandsModalOpen = true;
        this.isGroupBandsModalLoading = true;
        this.existingRecordId = null;
        this.existingRecord = null;
        this.editingLevelKey = null;
        this.levels = LEVEL_DEFAULTS.map(d => ({
            ...d, value: d.defaultValue, color: d.defaultColor, levelName: d.defaultName
        }));

        try {
            await this._reloadMembersIfGroupSelected({ skipLoadingFlag: true });
            const templateMember = (this.groupMemberRows || []).find(
                row => row.Assessment_ID__c && row.DBN__c
            );
            if (templateMember) {
                const matchingRecent = this.allAssessments.find(
                    row =>
                        row.Assessment_ID__c === templateMember.Assessment_ID__c &&
                        row.DBN__c === templateMember.DBN__c
                );
                if (matchingRecent) {
                    const existing = await getExistingScore({
                        assessmentId: matchingRecent.Id,
                        dbn: matchingRecent.DBN__c
                    });
                    if (existing) {
                        this.existingRecord = existing;
                        this.levels = this.levels.map(l => {
                            const sfVal = existing[FIELD_MAP[valueFieldKey(l.key)]];
                            const sfCol = existing[FIELD_MAP[colorFieldKey(l.key)]];
                            const sfName = existing[FIELD_MAP[nameFieldKey(l.key)]];
                            return {
                                ...l,
                                value: sfVal != null ? sfVal : l.value,
                                color: sfCol || l.defaultColor,
                                levelName: sfName || l.defaultName
                            };
                        });
                    }
                }
            }
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
        }
        this.isGroupBandsModalLoading = false;
    }

    closeGroupBandsModal() {
        this.isGroupBandsModalOpen = false;
        this.isGroupBandsModalLoading = false;
        this.isGroupBandsSaving = false;
        this.existingRecord = null;
        this.editingLevelKey = null;
        this.levels = [];
    }

    async handleSaveGroupBands() {
        if (this.hasSequentialError) {
            this._toast('Error', this.sequentialError, 'error');
            return;
        }
        this.isGroupBandsSaving = true;
        try {
            const result = await saveProficiencyScoresForRollupGroup({
                groupId: this.selectedRollupGroupId,
                level1Below: this._val('1'),
                level2Min: this._val('2'),
                level3Min: this._val('3'),
                level4Min: this._val('4'),
                level5Min: this._val('5'),
                level1Color: this._col('1'),
                level2Color: this._col('2'),
                level3Color: this._col('3'),
                level4Color: this._col('4'),
                level5Color: this._col('5'),
                level1Name: this._name('1'),
                level2Name: this._name('2'),
                level3Name: this._name('3'),
                level4Name: this._name('4'),
                level5Name: this._name('5')
            });
            const count = result?.updatedCount ?? 0;
            this._toast(
                'Success',
                `Performance bands saved for ${count} assessment${count === 1 ? '' : 's'} in this group.`,
                'success'
            );
            this.closeGroupBandsModal();
            await this.loadData();
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
        }
        this.isGroupBandsSaving = false;
    }

    // ── Add / Remove levels ──

    handleAddLevel() {
        if (!this.hasLevel4) {
            const l4 = LEVEL_DEFAULTS.find(d => d.key === '4');
            let newLevel = { ...l4, value: l4.defaultValue, color: l4.defaultColor, levelName: l4.defaultName };
            if (this.existingRecord) {
                const sfVal  = this.existingRecord[FIELD_MAP[valueFieldKey('4')]];
                const sfName = this.existingRecord[FIELD_MAP[nameFieldKey('4')]];
                if (sfVal != null) newLevel.value = sfVal;
                if (sfName) newLevel.levelName = sfName;
            }
            this.levels = [...this.levels, newLevel].sort((a, b) => a.num - b.num);
        } else if (!this.hasLevel5) {
            let newLevel = { ...LEVEL5_DEFAULT, value: LEVEL5_DEFAULT.defaultValue, color: LEVEL5_DEFAULT.defaultColor, levelName: LEVEL5_DEFAULT.defaultName };
            if (this.existingRecord) {
                const sfVal  = this.existingRecord[FIELD_MAP[valueFieldKey('5')]];
                const sfName = this.existingRecord[FIELD_MAP[nameFieldKey('5')]];
                if (sfVal != null) newLevel.value = sfVal;
                if (sfName) newLevel.levelName = sfName;
            }
            this.levels = [...this.levels, newLevel].sort((a, b) => a.num - b.num);
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
        const level = this.levels.find(l => l.key === key);
        if (level && (key === '4' || key === '5')) {
            this.levels = this.levels.filter(l => l.key !== key);
            this._applyColorPalette();
        }
    }

    // ── Inline label editing ──

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
        const def = LEVEL_DEFAULTS.find(d => d.key === key) || LEVEL5_DEFAULT;
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

    // ── Level inputs ──

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

    // ── Save ──

    async handleSave() {
        if (this.hasSequentialError) {
            this._toast('Error', this.sequentialError, 'error');
            return;
        }

        this.isSaving = true;
        try {
            const params = {
                recordId: this.existingRecordId || '',
                assessmentId: this.selectedAssessment.Id,
                assessmentName: this.selectedAssessment.Assessment_Name__c,
                dbn: this.selectedAssessment.DBN__c,
                level1Below: this._val('1'),
                level2Min:   this._val('2'),
                level3Min:   this._val('3'),
                level4Min:   this._val('4'),
                level5Min:   this._val('5'),
                level1Color: this._col('1'),
                level2Color: this._col('2'),
                level3Color: this._col('3'),
                level4Color: this._col('4'),
                level5Color: this._col('5'),
                level1Name:  this._name('1'),
                level2Name:  this._name('2'),
                level3Name:  this._name('3'),
                level4Name:  this._name('4'),
                level5Name:  this._name('5')
            };
            await saveProficiencyScore(params);
            this._toast('Success', 'Proficiency scores saved successfully.', 'success');
            this.closeModal();
            await this.loadData();
        } catch (error) {
            this._toast('Error', this._errMsg(error), 'error');
        }
        this.isSaving = false;
    }

    // ── Helpers ──

    _val(key) {
        const l = this.levels.find(lv => lv.key === key);
        return l ? l.value : null;
    }
    _col(key) {
        const l = this.levels.find(lv => lv.key === key);
        return l ? l.color : null;
    }
    _name(key) {
        const l = this.levels.find(lv => lv.key === key);
        return l ? (l.levelName || null) : null;
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

    _sortData(field, dir, data) {
        const m = dir === 'asc' ? 1 : -1;
        return data.sort((a, b) => {
            const va = a[field] || '';
            const vb = b[field] || '';
            return va > vb ? m : va < vb ? -m : 0;
        });
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    _errMsg(error) {
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return 'An unknown error occurred.';
    }
}