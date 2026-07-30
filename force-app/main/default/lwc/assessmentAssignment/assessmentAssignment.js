import { LightningElement, wire, track } from 'lwc';
import getRecentAssessments from '@salesforce/apex/AssessmentAssignmentController.getRecentAssessments';
import getDashboardTree from '@salesforce/apex/AssessmentAssignmentController.getDashboardTree';
import assignAssessment from '@salesforce/apex/AssessmentAssignmentController.assignAssessment';
import moveAssessmentInTree from '@salesforce/apex/AssessmentAssignmentController.moveAssessmentInTree';
import createNewMenuPage from '@salesforce/apex/AssessmentAssignmentController.createNewMenuPage';
import createNewSubmenuPage from '@salesforce/apex/AssessmentAssignmentController.createNewSubmenuPage';
import reorderNode from '@salesforce/apex/AssessmentAssignmentController.reorderNode';
import softDeleteAssessment from '@salesforce/apex/AssessmentAssignmentController.softDeleteAssessment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { label: 'Assessment ID', fieldName: 'Assessment_ID__c', type: 'text', sortable: true },
    { label: 'Assessment Name', fieldName: 'Assessment_Name__c', type: 'text', wrapText: true, sortable: true },
    { label: 'DBN', fieldName: 'DBN__c', type: 'text', sortable: true },
    { label: 'Created Date', fieldName: 'Created_Date__c', type: 'date', sortable: true },
    {
        label: 'Assign',
        type: 'button',
        initialWidth: 120,
        typeAttributes: { label: 'Assign', name: 'assign', variant: 'brand' }
    },
    {
        label: 'Delete',
        type: 'button',
        initialWidth: 120,
        typeAttributes: { label: 'Delete', name: 'delete', variant: 'destructive' }
    }
];

const EXPAND_DELAY_MS = 700;

const PAGE_SIZE_OPTIONS = [
    { label: '10', value: '10' },
    { label: '25', value: '25' },
    { label: '50', value: '50' },
    { label: '100', value: '100' }
];

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

export default class AssessmentAssignment extends LightningElement {
    columns = COLUMNS;
    pageSizeOptions = PAGE_SIZE_OPTIONS;
    allAssessments = [];
    wiredAssessmentsResult;
    isLoading = true;
    sortedBy = 'CreatedDate';
    sortDirection = 'desc';

    searchTerm = '';
    currentPage = 1;
    pageSize = 100;

    isModalOpen = false;
    selectedAssessment = null;
    selectedAcademicYear = DEFAULT_ACADEMIC_YEAR;
    academicYearOptions = ACADEMIC_YEAR_OPTIONS;

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

    @wire(getRecentAssessments)
    wiredAssessments(result) {
        this.wiredAssessmentsResult = result;
        if (result.data) {
            this.allAssessments = this.sortData(
                this.sortedBy, this.sortDirection, [...result.data]
            );
            this.currentPage = 1;
            this.isLoading = false;
        } else if (result.error) {
            this.isLoading = false;
        }
    }

    get filteredAssessments() {
        if (!this.searchTerm) {
            return this.allAssessments;
        }
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

    get hasFilteredResults() {
        return this.filteredAssessments && this.filteredAssessments.length > 0;
    }

    get showingRange() {
        const filtered = this.filteredAssessments;
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
        return this.isDragging && this.dragType === 'new'
            ? 'drag-card drag-card-dragging' : 'drag-card';
    }

    // ── Search + pagination ──

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.currentPage = 1;
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

    // ── Table handlers ──

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortDirection = sortDirection;
        this.allAssessments = this.sortData(fieldName, sortDirection, [...this.allAssessments]);
        this.currentPage = 1;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        if (action.name === 'assign') {
            this.openAssignModal(row);
        } else if (action.name === 'delete') {
            this.handleSoftDelete(row);
        }
    }

    async handleSoftDelete(row) {
        try {
            await softDeleteAssessment({
                recordId: row.Id,
                assessmentId: row.Assessment_ID__c
            });
            this.showToast('Success',
                `"${row.Assessment_Name__c}" has been removed.`, 'success');
            return refreshApex(this.wiredAssessmentsResult);
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        }
    }

    // ── Modal lifecycle ──

    async openAssignModal(row) {
        this.selectedAssessment = row;
        this.selectedAcademicYear = DEFAULT_ACADEMIC_YEAR;
        this.isModalOpen = true;
        this.isTreeLoading = true;
        this.isPlaced = false;
        this.treeData = [];
        this._autoExpandedIds = new Map();

        try {
            await this._loadDashboardTree();
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    async handleAcademicYearChange(event) {
        this.selectedAcademicYear = event.detail.value;
        this.isTreeLoading = true;
        this._autoExpandedIds = new Map();
        try {
            await this._loadDashboardTree();
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    async _loadDashboardTree() {
        const tree = await getDashboardTree({
            dbn: this.selectedAssessment.DBN__c,
            academicYear: this.selectedAcademicYear
        });
        this.treeData = this._initTree(tree);
    }

    closeModal() {
        this.isModalOpen = false;
        this.selectedAssessment = null;
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
        return refreshApex(this.wiredAssessmentsResult);
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
        const dbn = this.selectedAssessment ? this.selectedAssessment.DBN__c : '';
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
                draggableStr: 'true',
                isMenuStr: isMenu ? 'true' : 'false',
                expandIcon: expanded ? 'utility:chevrondown' : 'utility:chevronright',
                nodeClass: 'tree-node' +
                    (indent > 0 ? ' indent-' + indent : '') +
                    (isMenu ? ' tree-node-folder' : '') +
                    (node.isAssessment === true ? ' tree-node-assessment' : ''),
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
        this.dragType = 'new';
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', 'new-assessment');
        this._addDraggingClass();
    }

    // ── Drag: existing placed assessment ──

    handleTreeItemDragStart(event) {
        const el = event.currentTarget;
        const hasAssessment = el.dataset.assessmentId && el.dataset.assessmentId !== 'null'
            && el.dataset.assessmentId !== 'undefined';
        this.isDragging = true;
        this.dragType = hasAssessment ? 'move' : 'reorder';
        this.dragItemData = {
            id: el.dataset.id,
            level: parseInt(el.dataset.level, 10),
            label: el.dataset.label,
            assessmentId: el.dataset.assessmentId,
            isAssessment: hasAssessment
        };
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', hasAssessment ? 'move-assessment' : 'reorder-node');
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

        if (this.dragType === 'new') {
            await this._placeNew(parentId, targetLevel, newSort);
        } else if (this.dragType === 'move' && this.dragItemData) {
            await this._moveExisting(parentId, targetLevel, newSort);
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

    async _placeNew(parentId, targetLevel, sortOrder) {
        this.isTreeLoading = true;
        try {
            await assignAssessment({
                assessmentId: this.selectedAssessment.Assessment_ID__c,
                assessmentName: this.selectedAssessment.Assessment_Name__c,
                parentId,
                selectedLevel: targetLevel,
                recentAssessmentRecordId: this.selectedAssessment.Id,
                sortOrder,
                academicYear: this.selectedAcademicYear
            });

            this.showToast('Success',
                `"${this.selectedAssessment.Assessment_Name__c}" placed successfully.`,
                'success');
            this.isPlaced = true;

            await this._loadDashboardTree();
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    async _moveExisting(parentId, targetLevel, sortOrder) {
        this.isTreeLoading = true;
        const data = this.dragItemData;
        try {
            await moveAssessmentInTree({
                existingRecordId: data.id,
                fromLevel: data.level,
                newParentId: parentId,
                toLevel: targetLevel,
                sortOrder,
                assessmentName: data.label,
                assessmentId: data.assessmentId,
                academicYear: this.selectedAcademicYear
            });

            this.showToast('Success', `"${data.label}" moved.`, 'success');

            await this._loadDashboardTree();
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

            await this._loadDashboardTree();
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
                    dbn: this.selectedAssessment.DBN__c,
                    customName: name,
                    academicYear: this.selectedAcademicYear
                });
            }

            this.showToast('Success', `"${name}" created.`, 'success');
            await this._loadDashboardTree();
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
        if (typeof error === 'string') return error;
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
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