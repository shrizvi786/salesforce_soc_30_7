import { LightningElement, wire, track } from 'lwc';
import getRows from '@salesforce/apex/HmhAssessmentSettingsController.getRows';
import savePerformanceBands from '@salesforce/apex/HmhAssessmentSettingsController.savePerformanceBands';
import getPerformanceBands from '@salesforce/apex/HmhAssessmentSettingsController.getPerformanceBands';
import updateHideAndSync from '@salesforce/apex/HmhAssessmentSettingsController.updateHideAndSync';
import deleteHmhAssessmentSetting from '@salesforce/apex/HmhAssessmentSettingsController.deleteHmhAssessmentSetting';
import getDashboardTreeForHmh from '@salesforce/apex/HmhAssessmentDashboardController.getDashboardTreeForHmh';
import assignHmhAssessmentSetting from '@salesforce/apex/HmhAssessmentDashboardController.assignHmhAssessmentSetting';
import moveHmhAssessmentInTree from '@salesforce/apex/HmhAssessmentDashboardController.moveHmhAssessmentInTree';
import createNewMenuPage from '@salesforce/apex/AssessmentAssignmentController.createNewMenuPage';
import createNewSubmenuPage from '@salesforce/apex/AssessmentAssignmentController.createNewSubmenuPage';
import reorderNode from '@salesforce/apex/AssessmentAssignmentController.reorderNode';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Initial 3-level set rendered when the modal opens with no saved bands.
// Below Level 0-64.99% / On Level 65-79.99% / Above Level 80%+.
const LEVEL_DEFAULTS = [
    { key: '1', num: 1, defaultName: 'Below Level', defaultColor: '#E24B4A', defaultValue: 65 },
    { key: '2', num: 2, defaultName: 'On Level',    defaultColor: '#EF9F27', defaultValue: 65 },
    { key: '3', num: 3, defaultName: 'Above Level', defaultColor: '#639922', defaultValue: 80 }
];

// Level 4 is only added when the user clicks "Add Level 4".
const LEVEL4_DEFAULT = {
    key: '4',
    num: 4,
    defaultName: 'Level 4',
    defaultColor: '#378add',
    defaultValue: 85
};

// Level 5 is intentionally disabled on this admin UI — kept commented for future re-enable.
// const LEVEL5_DEFAULT = {
//     key: '5',
//     num: 5,
//     defaultName: 'Level 5',
//     defaultColor: '#378add',
//     defaultValue: null
// };

const COLOR_PALETTES = {
    3: ['#E24B4A', '#EF9F27', '#639922'],
    4: ['#E24B4A', '#EF9F27', '#639922', '#378add']
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

const TABLE_COLUMNS = [
    { label: 'Assessment Settings Name', fieldName: 'name', type: 'text', wrapText: true, sortable: true },
    {
        label: 'Hide',
        fieldName: 'hide',
        type: 'hmhBoolToggle',
        sortable: true,
        initialWidth: 84,
        typeAttributes: {
            settingId: { fieldName: 'settingId' },
            boolVal: { fieldName: 'hide' },
            mode: 'hide'
        }
    },
    { label: 'DBN', fieldName: 'dbn', type: 'text', sortable: true },
    { label: 'Assigned', fieldName: 'assigned', type: 'boolean', initialWidth: 96 },
    {
        label: 'Delete',
        fieldName: 'deleted',
        type: 'hmhBoolToggle',
        sortable: false,
        initialWidth: 88,
        typeAttributes: {
            settingId: { fieldName: 'settingId' },
            boolVal: { fieldName: 'deleted' },
            mode: 'delete'
        }
    },
    {
        label: 'Performance Band',
        type: 'hmhPerfBand',
        sortable: false,
        initialWidth: 140,
        typeAttributes: {
            settingId: { fieldName: 'settingId' }
        }
    },
    {
        label: 'Assign Dashboard',
        type: 'hmhAssignBtn',
        sortable: false,
        initialWidth: 150,
        typeAttributes: {
            settingId: { fieldName: 'settingId' }
        }
    },
    {
        label: 'Created Date',
        fieldName: 'createdDate',
        type: 'date',
        sortable: true,
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    }
];

const EXPAND_DELAY_MS = 700;

export default class HmhAssessmentSettingsAdmin extends LightningElement {
    columns = TABLE_COLUMNS;

    /** Bump after saves/toggles so the datatable remounts (checkbox state + clears stale UI). */
    @track datatableRenderKey = 0;

    rows = [];
    wiredRowsResult;
    isLoadingRows = true;
    sortedBy = 'createdDate';
    sortDirection = 'desc';

    isAssignModalOpen = false;
    selectedAssignRow = null;

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
            this.rows = this.sortData(this.sortedBy, this.sortDirection, [...result.data]);
            this.isLoadingRows = false;
        } else if (result.error) {
            this.isLoadingRows = false;
            // eslint-disable-next-line no-console
            console.error(result.error);
        }
    }

    get hasRows() {
        return this.rows && this.rows.length > 0;
    }

    get rowCount() {
        return this.rows ? this.rows.length : 0;
    }

    get hasTreeData() {
        return this.treeData && this.treeData.length > 0;
    }

    get dragCardClass() {
        return this.isDragging && this.dragType === 'hmh-new'
            ? 'drag-card drag-card-dragging'
            : 'drag-card';
    }

    // ── Table handlers ──

    handleSort(event) {
        const { fieldName, sortDirection } = event.detail;
        this.sortedBy = fieldName;
        this.sortDirection = sortDirection;
        this.rows = this.sortData(fieldName, sortDirection, [...this.rows]);
    }

    async handleSettingToggle(event) {
        const { settingId, mode, value } = event.detail || {};
        if (!settingId || !mode) {
            return;
        }

        try {
            if (mode === 'hide') {
                await updateHideAndSync({ hmhSettingId: settingId, hideVal: value });
                this.showToast('Saved', 'Hide updated.', 'success');
            } else if (mode === 'delete') {
                if (value !== true) {
                    return;
                }
                const ok = window.confirm(
                    'Delete this HMH Assessment Setting? This cannot be undone.'
                );
                if (!ok) {
                    this.datatableRenderKey += 1;
                    return;
                }
                await deleteHmhAssessmentSetting({ hmhSettingId: settingId });
                this.showToast('Deleted', 'Setting removed.', 'success');
            } else {
                return;
            }

            await refreshApex(this.wiredRowsResult);
            this.datatableRenderKey += 1;
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
            this.datatableRenderKey += 1;
        }
    }

    handleBandEdit(event) {
        const sid = event.detail.settingId;
        const row = this.rows.find(r => r.settingId === sid);
        if (row) {
            this.openBandsModal(row);
        }
    }

    handleBandAssign(event) {
        const sid = event.detail.settingId;
        const row = this.rows.find(r => r.settingId === sid);
        if (row) {
            this.openAssignModal(row);
        }
    }

    // ── Assign modal lifecycle ──

    async openAssignModal(row) {
        this.selectedAssignRow = row;
        this.isAssignModalOpen = true;
        this.isTreeLoading = true;
        this.isPlaced = false;
        this.treeData = [];
        this._autoExpandedIds = new Map();

        try {
            const tree = await getDashboardTreeForHmh({ dbn: row.dbn });
            this.treeData = this._initTree(tree);
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    closeAssignModal() {
        this.isAssignModalOpen = false;
        this.selectedAssignRow = null;
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

            const hmhSettingId = node.hmhSettingId || '';
            const highlightPlacement = node.isAssessment === true || !!node.hmhSettingId;

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
                hmhSettingId,
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
        this.dragType = 'hmh-new';
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', 'hmh-new');
        this._addDraggingClass();
    }

    // ── Drag: existing placed HMH row ──

    handleTreeItemDragStart(event) {
        const el = event.currentTarget;
        const hmhSettingId = el.dataset.hmhSettingId;
        const hasHmh = hmhSettingId && hmhSettingId !== 'null' && hmhSettingId !== 'undefined';
        this.isDragging = true;
        this.dragType = hasHmh ? 'hmh-move' : 'reorder';
        this.dragItemData = {
            id: el.dataset.id,
            level: parseInt(el.dataset.level, 10),
            label: el.dataset.label,
            hmhSettingId,
            isHmhMove: hasHmh
        };
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', hasHmh ? 'hmh-move' : 'reorder-node');
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

        if (this.dragType === 'hmh-new') {
            await this._placeNewHmh(parentId, targetLevel, newSort);
        } else if (this.dragType === 'hmh-move' && this.dragItemData) {
            await this._moveHmhInTree(parentId, targetLevel, newSort);
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

    async _placeNewHmh(parentId, targetLevel, sortOrder) {
        this.isTreeLoading = true;
        try {
            await assignHmhAssessmentSetting({
                hmhSettingId: this.selectedAssignRow.settingId,
                parentId,
                selectedLevel: targetLevel,
                sortOrder
            });

            this.showToast('Success',
                `"${this.selectedAssignRow.name}" placed successfully.`,
                'success');
            this.isPlaced = true;

            const tree = await getDashboardTreeForHmh({ dbn: this.selectedAssignRow.dbn });
            this.treeData = this._initTree(tree);
        } catch (error) {
            this.showToast('Error', this.extractErrorMessage(error), 'error');
        } finally {
            this.isTreeLoading = false;
        }
    }

    async _moveHmhInTree(parentId, targetLevel, sortOrder) {
        this.isTreeLoading = true;
        const data = this.dragItemData;
        try {
            await moveHmhAssessmentInTree({
                hmhSettingId: data.hmhSettingId,
                existingRecordId: data.id,
                fromLevel: data.level,
                newParentId: parentId,
                toLevel: targetLevel,
                sortOrder
            });

            this.showToast('Success', `"${data.label}" moved.`, 'success');

            const tree = await getDashboardTreeForHmh({ dbn: this.selectedAssignRow.dbn });
            this.treeData = this._initTree(tree);
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

            const tree = await getDashboardTreeForHmh({ dbn: this.selectedAssignRow.dbn });
            this.treeData = this._initTree(tree);
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
                    customName: name
                });
            } else {
                await createNewMenuPage({
                    dbn: this.selectedAssignRow.dbn,
                    customName: name
                });
            }

            this.showToast('Success', `"${name}" created.`, 'success');
            const tree = await getDashboardTreeForHmh({ dbn: this.selectedAssignRow.dbn });
            this.treeData = this._initTree(tree);
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
            const dto = await getPerformanceBands({ hmhSettingId: row.settingId });
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
        return this.selectedBandsRow
            ? `Performance bands — ${this.selectedBandsRow.name}`
            : 'Performance bands';
    }

    get hasLevel4() {
        return this.levels.some(l => l.key === '4');
    }

    // Level 5 is disabled on this UI — only the optional Level 4 add button is exposed.
    get canAddLevel() {
        return !this.hasLevel4;
    }

    get addLevelLabel() {
        return this.hasLevel4 ? '' : 'Add Level 4';
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
                canRemove: l.key === '4',
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
            (dto.level4Min !== undefined && dto.level4Min !== null) ||
            dto.level4Color ||
            dto.level4Name
        ) {
            merged.push({
                ...LEVEL4_DEFAULT,
                value:
                    dto.level4Min !== undefined && dto.level4Min !== null
                        ? dto.level4Min
                        : LEVEL4_DEFAULT.defaultValue,
                color: dto.level4Color || LEVEL4_DEFAULT.defaultColor,
                levelName: dto.level4Name || LEVEL4_DEFAULT.defaultName
            });
        }
        return merged.sort((a, b) => a.num - b.num);
    }

    handleAddLevel() {
        if (!this.hasLevel4) {
            this.levels = [...this.levels, {
                ...LEVEL4_DEFAULT,
                value: LEVEL4_DEFAULT.defaultValue,
                color: LEVEL4_DEFAULT.defaultColor,
                levelName: LEVEL4_DEFAULT.defaultName
            }].sort((a, b) => a.num - b.num);
        }
        // Level 5 add path is intentionally disabled — see commented LEVEL5_DEFAULT above.
        // else if (!this.hasLevel5) {
        //     this.levels = [...this.levels, {
        //         ...LEVEL5_DEFAULT,
        //         value: LEVEL5_DEFAULT.defaultValue,
        //         color: LEVEL5_DEFAULT.defaultColor,
        //         levelName: LEVEL5_DEFAULT.defaultName
        //     }].sort((a, b) => a.num - b.num);
        // }
        this._applyColorPalette();
    }

    handleRemoveLevel(event) {
        const key = event.currentTarget.dataset.level;
        this.levels = this.levels.filter(l => l.key !== key);
        this._applyColorPalette();
    }

    handleBadgeClick(event) {
        const key = event.currentTarget.dataset.level;
        if (key === '4') {
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
        const def = LEVEL_DEFAULTS.find(d => d.key === key) || LEVEL4_DEFAULT;
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
                hmhSettingId: this.selectedBandsRow.settingId,
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