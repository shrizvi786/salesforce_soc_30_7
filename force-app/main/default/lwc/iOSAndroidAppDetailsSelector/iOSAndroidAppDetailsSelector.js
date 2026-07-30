// testing code for pass offset and limit and get all ids also for select all
// Working code with all functionality tested.

// import { LightningElement, track, wire } from 'lwc';
// import getFieldDescriptionsAndRecords from '@salesforce/apex/MassPushNotificationController.getFieldDescriptionsAndRecords';
// import getAllRecordIds from '@salesforce/apex/MassPushNotificationController.getAllRecordIds';
// import { NavigationMixin } from 'lightning/navigation';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// // Constants for operators
// const OPERATORS = {
//     EQUALS: '=',
//     NOT_EQUAL: '!=',
//     LESS_THAN: '<',
//     GREATER_THAN: '>',
//     LESS_OR_EQUAL: '<=',
//     GREATER_OR_EQUAL: '>=',
//     CONTAINS: 'LIKE',
//     NOT_CONTAINS: 'NOT LIKE',
//     STARTS_WITH: 'STARTS WITH'
// };

// // Object options for dropdown
// const OBJECT_OPTIONS = [
//     { label: 'Schools', value: 'iOS_and_Android_App_Details__c' },
//     { label: 'Staff', value: 'Contact' }
// ];

// export default class MassPushNotification extends NavigationMixin(LightningElement) {
//     // Existing tracked properties
//     @track selectedObject = 'iOS_and_Android_App_Details__c';
//     @track objectOptions = OBJECT_OPTIONS;
//     @track records = [];
//     @track filteredRecords = [];
//     @track selectedRecords = [];
//     @track selectAll = false;
//     @track filterCriteria = [];
//     @track fieldOptions = [];
//     @track operatorOptions = [
//         { label: 'equals', value: OPERATORS.EQUALS },
//         { label: 'not equal to', value: OPERATORS.NOT_EQUAL },
//         { label: 'less than', value: OPERATORS.LESS_THAN },
//         { label: 'greater than', value: OPERATORS.GREATER_THAN },
//         { label: 'less or equal', value: OPERATORS.LESS_OR_EQUAL },
//         { label: 'greater or equal', value: OPERATORS.GREATER_OR_EQUAL },
//         { label: 'contains', value: OPERATORS.CONTAINS },
//         { label: 'does not contain', value: OPERATORS.NOT_CONTAINS },
//         { label: 'starts with', value: OPERATORS.STARTS_WITH }
//     ];
//     @track showFilterPanel = false;
//     @track showFilterEditModal = false;
//     @track editingFilter = { field: '', operator: '=', value: '', valueOptions: [] };
//     @track editingIndex = null;
//     @track isLoading = true;
//     @track loadedCount = 500;
//     @track isLoadingMore = false;
//     @track noRecordsFound = false;
//     @track wiredDataResult;
//     @track totalSize = 0;
//     @track offset = 0;
//     @track limit = 500;

//     // iOS/Android Notification Modal properties
//     @track showIOSNotificationModal = false;
//     @track iosNotificationTitle = '';
//     @track iosNotificationBody = '';
//     @track iosNotificationImageUrl = '';
//     @track iosNotificationLaunchUrl = '';
//     @track iosScheduledDate = '';
//     @track iosScheduledTime = '';
//     @track iosIsPinChecked = false;

//     // Contact Notification Modal properties
//     @track showContactNotificationModal = false;
//     @track contactNotificationTitle = '';
//     @track contactNotificationBody = '';
//     @track contactNotificationImageUrl = '';
//     @track contactNotificationLaunchUrl = '';

//     // Poll Modal properties
//     @track showIOSPollModal = false;
//     @track pollQuestion = '';
//     @track pollOptions = [
//         { id: 'option-1', value: '', placeholder: 'Enter option 1', isRequired: true },
//         { id: 'option-2', value: '', placeholder: 'Enter option 2', isRequired: true }
//     ];

//     @track pollEndDate = '';
//     @track pollEndTime = '';
//     @track pollQuestionId = null;
//     @track nextPollOptionId = 3;

//     // Spinner properties
//     @track isIOSModalLoading = false;
//     @track isContactModalLoading = false;

//     @track iosPinEndDate = '';

//     @track pollButtonLabel = 'Add Poll'; // Add this line

//     @track storedPollData = null;

//     // commented code for sucess PopUp

//     // @track showSuccessModal = false;
//     // @track successRecordCount = 0;

//     // // Close success modal
//     // closeSuccessModal() {
//     //     this.showSuccessModal = false;
//     // }

//     // Getters for object type
//     get isIOSObject() {
//         return this.selectedObject === 'iOS_and_Android_App_Details__c';
//     }

//     get isContactObject() {
//         return this.selectedObject === 'Contact';
//     }

//     get selectedObjectLabel() {
//         const obj = this.objectOptions.find(opt => opt.value === this.selectedObject);
//         return obj ? obj.label : this.selectedObject;
//     }

//     get visibleRecords() {
//         return this.filteredRecords.slice(0, this.loadedCount);
//     }

//     get visibleRecordsWithRowNumber() {
//         return this.visibleRecords.map((record, idx) => ({
//             ...record,
//             rowNumber: idx + 1
//         }));
//     }

//     get totalRecords() {
//         return this.totalSize;
//     }

//     get selectedCount() {
//         return this.selectedRecords.length;
//     }

//     get isPushDisabled() {
//         return this.selectedCount === 0;
//     }

//     get isPollFormValid() {
//         const filledOptions = this.pollOptions.filter(opt => opt.value.trim() !== '');
//         return (
//             !this.pollQuestion.trim() ||
//             filledOptions.length < 2 ||
//             !this.pollEndDate ||
//             !this.pollEndTime
//         );
//     }

//     get isAddOptionDisabled() {
//         return this.pollOptions.length >= 5;
//     }

//     // Log selected IDs for debugging
//     logSelectedIds() {
//         console.log('Selected IDs:', this.selectedRecords);
//         console.log('Selected Object:', this.selectedObject);
//     }

//     // Handle object selection change

//     handleObjectChange(event) {
//         this.selectedObject = event.detail.value;
//         this.isLoading = true;
//         this.loadedCount = 500;
//         this.offset = 0;
//         this.limit = 500;
//         this.filterCriteria = [];
//         this.resetSelectionState();

//         // Reset poll data when changing the object type
//         this.storedPollData = null;
//         this.pollButtonLabel = 'Add Poll';
//         this.pollQuestionId = null;

//         this._scrollHandlerAttached = false;
//         this.wiredDataResult = null;
//         console.log('Object changed to:', this.selectedObject);
//     }


//     // Fetch data for the selected object
//     @wire(getFieldDescriptionsAndRecords, {
//         objectName: '$selectedObject',
//         filters: '$filterCriteria',
//         offset: '$offset',
//         recordLimit: '$limit'
//     })
//     wiredData(result) {
//         this.wiredDataResult = result;
//         if (result.data || result.error) {
//             this.isLoading = false;
//         }
//         if (result.data) {
//             const data = result.data;
//             this.totalSize = data.totalSize;
//             this.fieldOptions = data.fieldDescriptions
//                 .map(field => ({
//                     label: field.label,
//                     value: field.value,
//                     picklistValues: field.picklistValues
//                 }))
//                 .sort((a, b) => a.label.localeCompare(b.label));

//             // Append new records to the existing list
//             let newRecords = data.records.map(record => ({
//                 ...record,
//                 isSelected: this.selectedRecords.includes(record.Id)
//             }));

//             if (this.offset === 0) {
//                 this.records = newRecords;
//             } else {
//                 this.records = [...this.records, ...newRecords];
//             }

//             this.filteredRecords = [...this.records];
//             this.applyFilters();
//         } else if (result.error) {
//             console.error('Error loading data', result.error);
//         }
//     }

//     // Load more records on scroll
//     renderedCallback() {
//         if (!this._scrollHandlerAttached) {
//             const tableContainer = this.template.querySelector('.slds-table_container');
//             if (tableContainer) {
//                 tableContainer.addEventListener('scroll', this.handleTableScroll.bind(this));
//                 this._scrollHandlerAttached = true;
//             }
//         }
//     }

//     handleTableScroll(event) {
//         const container = event.target;
//         if (container.scrollTop + container.clientHeight >= container.scrollHeight - 100 &&
//             this.loadedCount < this.totalSize &&
//             !this.isLoadingMore) {
//             this.loadMoreRecords();
//         }
//     }

//     async loadMoreRecords() {
//         this.isLoadingMore = true;
//         this.offset += this.limit;

//         // Wait for the data to load
//         await new Promise(resolve => setTimeout(resolve, 300));

//         // After new records are loaded, update the UI to reflect selected records
//         this.records = this.records.map(record => ({
//             ...record,
//             isSelected: this.selectedRecords.includes(record.Id)
//         }));

//         this.filteredRecords = this.filteredRecords.map(record => ({
//             ...record,
//             isSelected: this.selectedRecords.includes(record.Id)
//         }));

//         this.loadedCount = this.records.length;
//         this.isLoadingMore = false;
//     }

//     resetSelectionState() {
//         this.selectAll = false;
//         this.selectedRecords = [];
//         this.records = this.records.map(record => ({
//             ...record,
//             isSelected: false
//         }));
//         this.filteredRecords = this.filteredRecords.map(record => ({
//             ...record,
//             isSelected: false
//         }));
//     }

//     // Filter panel handlers
//     openFilterPanel() {
//         this.showFilterPanel = true;
//     }

//     closeFilterPanel() {
//         this.showFilterPanel = false;
//     }

//     addFilter() {
//         this.editingFilter = { field: '', operator: '=', value: '', valueOptions: [] };
//         this.editingIndex = this.filterCriteria.length;
//         this.showFilterEditModal = true;
//         this.resetSelectionState(); // Reset selection state when a new filter is added
//     }

//     editFilter(event) {
//         const index = event.target.dataset.index;
//         const filter = this.filterCriteria[index];
//         this.editingFilter = { ...filter };
//         this.editingIndex = index;
//         this.showFilterEditModal = true;
//     }

//     closeEditFilterModal() {
//         this.showFilterEditModal = false;
//         this.editingFilter = { field: '', operator: '=', value: '', valueOptions: [] };
//         this.editingIndex = null;
//     }

//     handleEditFilterChange(event) {
//         const { name, value } = event.target;
//         let editingFilter = { ...this.editingFilter, [name]: value };
//         if (name === 'field') {
//             const selectedField = this.fieldOptions.find(option => option.value === value);
//             if (selectedField && selectedField.picklistValues) {
//                 editingFilter.valueOptions = selectedField.picklistValues.map(item => ({ label: item, value: item }));
//             } else {
//                 editingFilter.valueOptions = undefined;
//             }
//             editingFilter.value = '';
//             editingFilter.fieldLabel = selectedField ? selectedField.label : 'New Filter';
//         }
//         this.editingFilter = editingFilter;
//     }

//     saveEditFilter() {
//         let filter = { ...this.editingFilter };
//         if (!filter.fieldLabel) {
//             const selectedField = this.fieldOptions.find(option => option.value === filter.field);
//             filter.fieldLabel = selectedField ? selectedField.label : 'New Filter';
//         }
//         let criteria = [...this.filterCriteria];
//         criteria[this.editingIndex] = filter;
//         this.filterCriteria = criteria;
//         this.showFilterEditModal = false;
//         this.editingIndex = null;
//         this.resetSelectionState(); // Reset selection state when a filter is edited
//         this.applyFilters();
//     }

//     handlePopoverBackgroundClick(event) {
//         if (event.target === this.template.querySelector('.filter-popover-anchor')) {
//             this.closeEditFilterModal();
//         }
//     }

//     removeAllFilters() {
//         this.filterCriteria = [];
//         this.resetSelectionState(); // Reset selection state when all filters are removed
//         this.applyFilters();
//     }

//     removeFilter(event) {
//         const index = event.target.dataset.index;
//         this.filterCriteria = this.filterCriteria.filter((_, i) => i != index);
//         this.resetSelectionState(); // Reset selection state when a filter is removed
//         this.applyFilters();
//     }

//     applyFilters() {
//         this.filteredRecords = this.filterRecords(this.records);
//         this.syncSelectedRecords();

//         // Update selectAll state based on whether all visible records are selected
//         const visibleIds = this.visibleRecords.map(r => r.Id);
//         this.selectAll = visibleIds.length > 0 && visibleIds.every(id => this.selectedRecords.includes(id));
//     }


//     getNestedValue(obj, path) {
//         return path.split('.').reduce((acc, part) => acc && acc[part], obj);
//     }

//     filterRecords(records) {
//         if (this.filterCriteria.length > 0) {
//             return records.filter(record => {
//                 return this.filterCriteria.every(filter => {
//                     const fieldValue = this.getNestedValue(record, filter.field);
//                     return this.applyFilterCondition(fieldValue, filter);
//                 });
//             });
//         }
//         return records;
//     }

//     applyFilterCondition(fieldValue, filter) {
//         const filterValues = filter.value.split(',').map(v => v.trim().toUpperCase());
//         const fieldValueStr = String(fieldValue).toUpperCase();
//         switch (filter.operator) {
//             case OPERATORS.EQUALS:
//                 return filterValues.includes(fieldValueStr);
//             case OPERATORS.NOT_EQUAL:
//                 return !filterValues.includes(fieldValueStr);
//             case OPERATORS.LESS_THAN:
//                 return filterValues.some(val => fieldValueStr < val);
//             case OPERATORS.GREATER_THAN:
//                 return filterValues.some(val => fieldValueStr > val);
//             case OPERATORS.LESS_OR_EQUAL:
//                 return filterValues.some(val => fieldValueStr <= val);
//             case OPERATORS.GREATER_OR_EQUAL:
//                 return filterValues.some(val => fieldValueStr >= val);
//             case OPERATORS.CONTAINS:
//                 return filterValues.some(val => fieldValueStr.includes(val));
//             case OPERATORS.NOT_CONTAINS:
//                 return !filterValues.some(val => fieldValueStr.includes(val));
//             case OPERATORS.STARTS_WITH:
//                 return filterValues.some(val => fieldValueStr.startsWith(val));
//             default:
//                 return true;
//         }
//     }

//     syncSelectedRecords() {
//         const filteredIds = this.filteredRecords.map(r => r.Id);
//         this.selectedRecords = this.selectedRecords.filter(id => filteredIds.includes(id));
//     }

//     // Toggle select all
//     async toggleSelectAll(event) {
//         const isChecked = event.target.checked;
//         const visibleIds = this.visibleRecords.map(r => r.Id);

//         if (visibleIds.length === 0) {
//             this.selectAll = false;
//             return;
//         }

//         this.selectAll = isChecked;
//         if (isChecked) {
//             this.isLoading = true;
//             try {
//                 const allIds = await getAllRecordIds({
//                     objectName: this.selectedObject,
//                     filters: this.filterCriteria
//                 });
//                 this.selectedRecords = [...new Set(allIds)];

//                 // Update the UI to reflect selected records
//                 this.records = this.records.map(record => ({
//                     ...record,
//                     isSelected: allIds.includes(record.Id)
//                 }));

//                 this.filteredRecords = this.filteredRecords.map(record => ({
//                     ...record,
//                     isSelected: allIds.includes(record.Id)
//                 }));

//                 this.dispatchEvent(
//                     new ShowToastEvent({
//                         title: 'Success',
//                         message: `All ${this.totalSize} records selected!`,
//                         variant: 'success'
//                     })
//                 );
//             } catch (error) {
//                 console.error('Error fetching all record IDs:', error);
//             } finally {
//                 this.isLoading = false;
//                 this.logSelectedIds();
//             }
//         } else {
//             // Only remove the visible records from selectedRecords
//             this.selectedRecords = this.selectedRecords.filter(id => !visibleIds.includes(id));

//             // Update the UI to reflect unselected records
//             this.records = this.records.map(record => ({
//                 ...record,
//                 isSelected: this.selectedRecords.includes(record.Id)
//             }));

//             this.filteredRecords = this.filteredRecords.map(record => ({
//                 ...record,
//                 isSelected: this.selectedRecords.includes(record.Id)
//             }));
//         }
//     }

//     // Handle checkbox selection
//     handleCheckbox(event) {
//         const recordId = event.target.dataset.id;
//         const isChecked = event.target.checked;

//         this.records = this.records.map(record => {
//             if (record.Id === recordId) {
//                 return { ...record, isSelected: isChecked };
//             }
//             return record;
//         });

//         this.filteredRecords = this.filteredRecords.map(record => {
//             if (record.Id === recordId) {
//                 return { ...record, isSelected: isChecked };
//             }
//             return record;
//         });

//         if (isChecked) {
//             if (!this.selectedRecords.includes(recordId)) {
//                 this.selectedRecords = [...this.selectedRecords, recordId];
//             }
//         } else {
//             this.selectedRecords = this.selectedRecords.filter(id => id !== recordId);
//         }

//         const visibleIds = this.visibleRecords.map(r => r.Id);
//         this.selectAll = visibleIds.every(id => this.selectedRecords.includes(id));
//         this.logSelectedIds();
//     }

//     // Navigation handlers
//     handleSchoolNameClick(event) {
//         if (!this.isIOSObject) return;
//         const recordId = event.currentTarget.dataset.recordId;
//         this[NavigationMixin.Navigate]({
//             type: 'standard__recordPage',
//             attributes: {
//                 recordId: recordId,
//                 objectApiName: 'School_App__c',
//                 actionName: 'view'
//             }
//         });
//     }

//     handleAccountClick(event) {
//         const accountId = event.currentTarget.dataset.id;
//         this[NavigationMixin.Navigate]({
//             type: 'standard__recordPage',
//             attributes: {
//                 recordId: accountId,
//                 objectApiName: 'Account',
//                 actionName: 'view'
//             }
//         });
//     }

//     // iOS/Android Notification Modal Handlers
//     openNotificationModal() {
//         if (this.isIOSObject) {
//             console.log('Opening iOS/Android Notification Modal');
//             this.showIOSNotificationModal = true;
//         } else if (this.isContactObject) {
//             console.log('Opening Contact Notification Modal');
//             this.showContactNotificationModal = true;
//         }
//         this.logSelectedIds();
//     }

//     closeIOSNotificationModal() {
//         this.showIOSNotificationModal = false;
//         this.isIOSModalLoading = false;
//         this.iosNotificationTitle = '';
//         this.iosNotificationBody = '';
//         this.iosNotificationImageUrl = '';
//         this.iosNotificationLaunchUrl = '';
//         this.iosScheduledDate = '';
//         this.iosScheduledTime = '';
//         this.iosIsPinChecked = false;
//         this.iosPinEndDate = '';

//         // Reset poll data when closing the modal
//         this.storedPollData = null;
//         this.pollButtonLabel = 'Add Poll';
//         this.pollQuestionId = null;
//     }

//     handleIOSTitleChange(event) {
//         this.iosNotificationTitle = event.target.value;
//     }

//     handleIOSBodyChange(event) {
//         this.iosNotificationBody = event.target.value;
//     }

//     handleIOSImageUrlChange(event) {
//         this.iosNotificationImageUrl = event.target.value;
//     }

//     handleIOSLaunchUrlChange(event) {
//         this.iosNotificationLaunchUrl = event.target.value;
//     }

//     handleIOSScheduledDateChange(event) {
//         this.iosScheduledDate = event.target.value;
//     }

//     handleIOSScheduledTimeChange(event) {
//         this.iosScheduledTime = event.target.value;
//     }

//     handleIOSPinCheckboxChange(event) {
//         this.iosIsPinChecked = event.target.checked;
//     }

//     // Add this method to handle changes to the pin end date
//     handleIOSPinEndDateChange(event) {
//         this.iosPinEndDate = event.target.value;
//         console.log('Pin End Date selected:', this.iosPinEndDate);
//     }

//     closeContactNotificationModal() {
//         this.showContactNotificationModal = false;
//         this.isContactModalLoading = false;
//         this.contactNotificationTitle = '';
//         this.contactNotificationBody = '';
//         this.contactNotificationImageUrl = '';
//         this.contactNotificationLaunchUrl = '';
//     }


//     handleContactTitleChange(event) {
//         this.contactNotificationTitle = event.target.value;
//     }

//     handleContactBodyChange(event) {
//         this.contactNotificationBody = event.target.value;
//     }

//     handleContactImageUrlChange(event) {
//         this.contactNotificationImageUrl = event.target.value;
//     }

//     handleContactLaunchUrlChange(event) {
//         this.contactNotificationLaunchUrl = event.target.value;
//     }

//     // Poll Modal Handlers
//     // openIOSPollModal() {
//     //     this.showIOSPollModal = true;
//     // }
//     openIOSPollModal() {
//         this.showIOSPollModal = true;

//         // Pre-fill the poll modal if stored data exists
//         if (this.storedPollData) {
//             this.pollQuestion = this.storedPollData.question;
//             this.pollOptions = this.storedPollData.options.map((option, index) => ({
//                 id: `option-${index + 1}`,
//                 value: option,
//                 placeholder: `Enter option ${index + 1}`,
//                 isRequired: true,
//                 canDelete: index >= 2
//             }));
//             this.pollEndDate = this.storedPollData.endDate;
//             this.pollEndTime = this.storedPollData.endTime;
//         } else {
//             // Reset to default if no stored data
//             this.pollQuestion = '';
//             this.pollOptions = [
//                 { id: 'option-1', value: '', placeholder: 'Enter option 1', isRequired: true },
//                 { id: 'option-2', value: '', placeholder: 'Enter option 2', isRequired: true }
//             ];
//             this.pollEndDate = '';
//             this.pollEndTime = '';
//         }
//     }

//     closeIOSPollModal() {
//         this.showIOSPollModal = false;
//         this.pollQuestion = '';
//         this.pollOptions = [
//             { id: 'option-1', value: '', placeholder: 'Enter option 1' },
//             { id: 'option-2', value: '', placeholder: 'Enter option 2' }
//         ];
//         this.nextPollOptionId = 3;
//         this.pollEndDate = '';
//         this.pollEndTime = '';
//     }

//     handlePollQuestionChange(event) {
//         this.pollQuestion = event.target.value;
//     }

//     handlePollOptionChange(event) {
//         const index = parseInt(event.target.dataset.index);
//         const newOptions = [...this.pollOptions];
//         newOptions[index].value = event.target.value;
//         this.pollOptions = newOptions;
//     }

//     addPollOption() {
//         if (this.pollOptions.length < 5) {
//             const newOption = {
//                 id: `option-${this.nextPollOptionId}`,
//                 value: '',
//                 placeholder: `Enter option ${this.nextPollOptionId}`,
//                 isRequired: false,
//                 canDelete: true
//             };
//             this.pollOptions = [...this.pollOptions, newOption];
//             this.nextPollOptionId++;
//         }
//     }

//     removePollOption(event) {
//         const index = parseInt(event.target.dataset.index);
//         if (this.pollOptions.length > 2) {
//             this.pollOptions = this.pollOptions.filter((_, i) => i !== index);
//         } else {
//             this.dispatchEvent(
//                 new ShowToastEvent({
//                     title: 'Error',
//                     message: 'At least 2 options are required!',
//                     variant: 'error'
//                 })
//             );
//         }
//     }

//     handlePollEndDateChange(event) {
//         this.pollEndDate = event.target.value;
//     }

//     handlePollEndTimeChange(event) {
//         this.pollEndTime = event.target.value;
//     }

//     // Save Poll (API call)
//     savePoll() {
//         const options = this.pollOptions
//             .map((opt, index) => ({
//                 Poll_Option: opt.value,
//                 Sort_Order: index,
//                 Active_Status: "true"
//             }))
//             .filter(opt => opt.Poll_Option.trim() !== '');

//         if (options.length < 2) {
//             this.dispatchEvent(
//                 new ShowToastEvent({
//                     title: 'Error',
//                     message: 'Please provide at least 2 poll options!',
//                     variant: 'error'
//                 })
//             );
//             return;
//         }

//         const pollData = {
//             Account_Id: "0014W00002aAD6wQAG",
//             Poll_Question: this.pollQuestion,
//             Poll_Start_Date: new Date().toISOString().split('T')[0],
//             Poll_Start_Time: new Date().toISOString().split('T')[1].split('.')[0],
//             Poll_End_Date: this.pollEndDate,
//             Poll_End_Time: this.pollEndTime,
//             Active_Status: "true",
//             Poll_Options: options
//         };

//         this.isIOSModalLoading = true;

//         fetch('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/poll', {
//             method: 'POST',
//             headers: {
//                 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlYWNoZXIuc29sdmVkQHN5c3RlbS51c2VyIiwicm9sZSI6InRlYWNoZXIiLCJpZCI6IjAwM052MDAwMDBKQXk4MUlBRCIsImlhdCI6MTczMzQwNjAyNn0.Hnkzas3BJpT2bjeUAtMSNJxgaIdxBlebp29YlmgOoFU',
//                 'Content-Type': 'application/json'
//             },
//             body: JSON.stringify(pollData)
//         })
//             .then(response => {
//                 if (!response.ok) {
//                     throw new Error(`Failed to save poll: ${response.status} ${response.statusText}`);
//                 }
//                 return response.json();
//             })
//             .then(data => {
//                 this.dispatchEvent(
//                     new ShowToastEvent({
//                         title: '🎉 Success!',
//                         message: 'Poll saved successfully!',
//                         variant: 'success'
//                     })
//                 );
//                 this.pollQuestionId = data.body.Poll_Question.Id;

//                 // Store the poll data for editing
//                 this.storedPollData = {
//                     question: this.pollQuestion,
//                     options: this.pollOptions.map(opt => opt.value),
//                     endDate: this.pollEndDate,
//                     endTime: this.pollEndTime
//                 };

//                 this.pollButtonLabel = 'Edit Poll';
//                 this.closeIOSPollModal();
//             })
//             .catch(error => {
//                 console.error('Error saving poll:', error);
//                 this.dispatchEvent(
//                     new ShowToastEvent({
//                         title: 'Error',
//                         message: error.message,
//                         variant: 'error'
//                     })
//                 );
//             })
//             .finally(() => {
//                 this.isIOSModalLoading = false;
//             });
//     }

//     // Send iOS/Android Notification
//     sendIOSNotification() {
//         if (!this.iosNotificationTitle || !this.iosNotificationBody) {
//             this.dispatchEvent(
//                 new ShowToastEvent({
//                     title: 'Error',
//                     message: 'Title and Message are required!',
//                     variant: 'error'
//                 })
//             );
//             return;
//         }
//         // First confirmation
//         const firstConfirm = confirm('Are you sure you want to send this Push Notification to all the selected Schools?');
//         if (!firstConfirm) return;

//         // Second confirmation
//         const secondConfirm = confirm('You cannot undo this action. Continue?');
//         if (!secondConfirm) return;

//         const requestBody = {
//             ids: this.selectedRecords,
//             title: this.iosNotificationTitle,
//             message: this.iosNotificationBody,
//             imageUrl: this.iosNotificationImageUrl,
//             url: this.iosNotificationLaunchUrl,
//             scheduleDate: this.iosScheduledDate,
//             scheduleTime: this.iosScheduledTime,
//             pinned: this.iosIsPinChecked,
//             pollQuestionId: this.pollQuestionId,
//             pinEndDate: this.iosPinEndDate,
//         };

//         console.log('Request Body for iOS Notification:', JSON.stringify(requestBody));

//         this.isIOSModalLoading = true;
//         this.isLoading = true;

//         fetch('https://9nwyf9euuf.execute-api.us-east-2.amazonaws.com/prod/send-mass-push-notifications', {
//             method: 'POST',
//             headers: {
//                 'Authorization': 'r?ftDEZ_qdt=VjD#W@S2LM8FZT97Nx',
//                 'Content-Type': 'application/json',
//             },
//             body: JSON.stringify(requestBody),
//         })
//             .then(async response => {
//                 this.isLoading = false;
//                 const data = await response.json();
//                 console.log('Response Data :', data);
//                 if (response.ok) {
//                     this.dispatchEvent(
//                         new ShowToastEvent({
//                             title: '🎉 Success!',
//                             message: `Notification sent to ${this.selectedRecords.length} schools!`,
//                             variant: 'success'
//                         })
//                     );

//                     //    if (response.ok) {
//                     // this.successRecordCount = this.selectedRecords.length;
//                     // this.showSuccessModal = true;

//                     // Reset poll data after sending the push message
//                     this.storedPollData = null;
//                     this.pollButtonLabel = 'Add Poll';
//                     this.pollQuestionId = null;

//                     this.closeIOSNotificationModal();
//                     // Refresh the page after success
//                     // window.location.reload();
//                 } else {
//                     this.isIOSModalLoading = false;
//                     throw new Error(`Failed: ${response.status} ${response.statusText}`);
//                 }
//             })
//             .catch(error => {
//                 this.isLoading = false;
//                 this.isIOSModalLoading = false;
//                 this.dispatchEvent(
//                     new ShowToastEvent({
//                         title: 'Error',
//                         message: error.message,
//                         variant: 'error'
//                     })
//                 );
//             });
//     }

//     // Send Contact Notification
//     // sendContactNotification() {
//     //     if (!this.contactNotificationTitle || !this.contactNotificationBody) {
//     //         this.dispatchEvent(
//     //             new ShowToastEvent({
//     //                 title: 'Error',
//     //                 message: 'Title and Message are required!',
//     //                 variant: 'error'
//     //             })
//     //         );
//     //         return;
//     //     }

//     //     // First confirmation
//     //     const firstConfirm = confirm('Are you sure you want to send this Push Notification to all the selected Schools?');
//     //     if (!firstConfirm) return;

//     //     // Second confirmation
//     //     const secondConfirm = confirm('You cannot undo this action. Continue?');
//     //     if (!secondConfirm) return;

//     //     const attachments = this.contactNotificationImageUrl ? [{
//     //         sort_order: 0,
//     //         url: this.contactNotificationImageUrl
//     //     }] : [];

//     //     const requestBody = {
//     //         IsStaff_Story: true,
//     //         title: this.contactNotificationTitle,
//     //         message: this.contactNotificationBody,
//     //         attachments: attachments,
//     //         launch_url: this.contactNotificationLaunchUrl,
//     //         Story_Recepients: this.selectedRecords.map(id => ({
//     //             Teacher_Id: id
//     //         }))
//     //     };

//     //     console.log('Request Body for Contacts:', JSON.stringify(requestBody)); // Debugging line

//     //     this.isContactModalLoading = true;
//     //     this.isLoading = true;

//     //     fetch('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-and-social-feed/staff-story', {
//     //         method: 'POST',
//     //         headers: {
//     //             'Content-Type': 'application/json'
//     //         },
//     //         body: JSON.stringify(requestBody)
//     //     })
//     //         .then(response => {
//     //             this.isLoading = false;
//     //             console.log('Response Status:', response.status); // Debugging line
//     //             console.log('Response:', response); // Debugging line

//     //             if (response.ok) {
//     //                 this.dispatchEvent(
//     //                     new ShowToastEvent({
//     //                         title: '🎉 Success!',
//     //                         message: `Notification sent to ${this.selectedRecords.length} staff members!`,
//     //                         variant: 'success'
//     //                     })
//     //                 );
//     //                 // if (response.ok) {
//     //                 //     this.successRecordCount = this.selectedRecords.length;
//     //                 //     this.showSuccessModal = true;

//     //                 this.closeContactNotificationModal();
//     //                 // Refresh the page after success
//     //                 // window.location.reload();
//     //             } else {
//     //                 this.isContactModalLoading = false;
//     //                 return response.text().then(errorDetails => {
//     //                     throw new Error(`Failed: ${response.status} ${response.statusText}: ${errorDetails}`);
//     //                 });
//     //             }
//     //         })
//     //         .catch(error => {
//     //             this.isLoading = false;
//     //             this.isContactModalLoading = false;
//     //             console.error('Error:', error); // Debugging line
//     //             this.dispatchEvent(
//     //                 new ShowToastEvent({
//     //                     title: 'Error',
//     //                     message: error.message,
//     //                     variant: 'error'
//     //                 })
//     //             );
//     //         });
//     // }

//     // Send Contact Notification
//     sendContactNotification() {
//         if (!this.contactNotificationTitle || !this.contactNotificationBody) {
//             this.dispatchEvent(
//                 new ShowToastEvent({
//                     title: 'Error',
//                     message: 'Title and Message are required!',
//                     variant: 'error'
//                 })
//             );
//             return;
//         }

//         // First confirmation
//         const firstConfirm = confirm('Are you sure you want to send this Push Notification to all the selected Schools?');
//         if (!firstConfirm) return;

//         // Second confirmation
//         const secondConfirm = confirm('You cannot undo this action. Continue?');
//         if (!secondConfirm) return;

//         const attachments = this.contactNotificationImageUrl ? [{
//             sort_order: 0,
//             url: this.contactNotificationImageUrl
//         }] : [];

//         const requestBody = {
//             IsStaff_Story: true,
//             title: this.contactNotificationTitle,
//             message: this.contactNotificationBody,
//             attachments: attachments,
//             launch_url: this.contactNotificationLaunchUrl,
//             Story_Recepients: this.selectedRecords.map(id => ({
//                 Teacher_Id: id
//             }))
//         };

//         console.log('Request Body for Contacts:', JSON.stringify(requestBody));

//         this.isContactModalLoading = true;
//         this.isLoading = true;

//         fetch('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-and-social-feed/staff-story', {
//             method: 'POST',
//             headers: {
//                 'Content-Type': 'application/json'
//             },
//             body: JSON.stringify(requestBody)
//         })
//             .then(async response => {
//                 this.isLoading = false;
//                 const data = await response.json();
//                 console.log('Response Data:', data);
//                 if (response.ok && (!data.statusCode || data.statusCode === 200)) {
//                     // Only show success if the response body does NOT contain an error
//                     this.dispatchEvent(
//                         new ShowToastEvent({
//                             title: '🎉 Success!',
//                             message: `Notification sent to ${this.selectedRecords.length} staff members!`,
//                             variant: 'success'
//                         })
//                     );
//                     this.closeContactNotificationModal();
//                 } else {
//                     // Show error if the response body contains an error
//                     throw new Error(data.message || `Failed: ${response.status} ${response.statusText}`);
//                 }
//             })
//             .catch(error => {
//                 this.isLoading = false;
//                 this.isContactModalLoading = false;
//                 console.error('Error:', error);
//                 this.dispatchEvent(
//                     new ShowToastEvent({
//                         title: 'Error',
//                         message: error.message,
//                         variant: 'error'
//                     })
//                 );
//             });
//     }

// }


// Testing code for Above code and in which we add the filter Conditaion(working on 23-2-2026)

// import { LightningElement, track, wire } from 'lwc';
// import getFieldDescriptionsAndRecords from '@salesforce/apex/MassPushNotificationController.getFieldDescriptionsAndRecords';
// import getAllRecordIds from '@salesforce/apex/MassPushNotificationController.getAllRecordIds';
// import { NavigationMixin } from 'lightning/navigation';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// // Constants for operators
// const OPERATORS = {
//     EQUALS: '=',
//     NOT_EQUAL: '!=',
//     LESS_THAN: '<',
//     GREATER_THAN: '>',
//     LESS_OR_EQUAL: '<=',
//     GREATER_OR_EQUAL: '>=',
//     CONTAINS: 'LIKE',
//     NOT_CONTAINS: 'NOT LIKE',
//     STARTS_WITH: 'STARTS WITH'
// };

// // Object options for dropdown
// const OBJECT_OPTIONS = [
//     { label: 'Schools', value: 'iOS_and_Android_App_Details__c' },
//     { label: 'Staff', value: 'Contact' }
// ];

// export default class MassPushNotification extends NavigationMixin(LightningElement) {
//     // Existing tracked properties
//     @track selectedObject = 'iOS_and_Android_App_Details__c';
//     @track objectOptions = OBJECT_OPTIONS;
//     @track records = [];
//     @track filteredRecords = [];
//     @track selectedRecords = [];
//     @track selectAll = false;
//     @track filterCriteria = [];
//     @track fieldOptions = [];
//     @track operatorOptions = [
//         { label: 'equals', value: OPERATORS.EQUALS },
//         { label: 'not equal to', value: OPERATORS.NOT_EQUAL },
//         { label: 'less than', value: OPERATORS.LESS_THAN },
//         { label: 'greater than', value: OPERATORS.GREATER_THAN },
//         { label: 'less or equal', value: OPERATORS.LESS_OR_EQUAL },
//         { label: 'greater or equal', value: OPERATORS.GREATER_OR_EQUAL },
//         { label: 'contains', value: OPERATORS.CONTAINS },
//         { label: 'does not contain', value: OPERATORS.NOT_CONTAINS },
//         { label: 'starts with', value: OPERATORS.STARTS_WITH }
//     ];
//     @track showFilterPanel = false;
//     @track showFilterEditModal = false;
//     @track editingFilter = { field: '', operator: '=', value: '', valueOptions: [] };
//     @track editingIndex = null;
//     @track isLoading = true;
//     @track loadedCount = 500;
//     @track isLoadingMore = false;
//     @track noRecordsFound = false;
//     @track wiredDataResult;
//     @track totalSize = 0;
//     @track offset = 0;
//     @track limit = 500;

//     // iOS/Android Notification Modal properties
//     @track showIOSNotificationModal = false;
//     @track iosNotificationTitle = '';
//     @track iosNotificationBody = '';
//     @track iosNotificationImageUrl = '';
//     @track iosNotificationLaunchUrl = '';
//     @track iosScheduledDate = '';
//     @track iosScheduledTime = '';
//     @track iosIsPinChecked = false;

//     // Contact Notification Modal properties
//     @track showContactNotificationModal = false;
//     @track contactNotificationTitle = '';
//     @track contactNotificationBody = '';
//     @track contactNotificationImageUrl = '';
//     @track contactNotificationLaunchUrl = '';

//     // Poll Modal properties
//     @track showIOSPollModal = false;
//     @track pollQuestion = '';
//     @track pollOptions = [
//         { id: 'option-1', value: '', placeholder: 'Enter option 1', isRequired: true },
//         { id: 'option-2', value: '', placeholder: 'Enter option 2', isRequired: true }
//     ];

//     @track pollEndDate = '';
//     @track pollEndTime = '';
//     @track pollQuestionId = null;
//     @track nextPollOptionId = 3;

//     // Spinner properties
//     @track isIOSModalLoading = false;
//     @track isContactModalLoading = false;

//     @track iosPinEndDate = '';

//     @track pollButtonLabel = 'Add Poll'; // Add this line

//     @track storedPollData = null;

//     @track appliedCustomLogic = '';    // Add this line for dynamic filters
//     @track customFilterLogic = '';     // Add this line for dynamic filters

//     // commented code for sucess PopUp

//     // @track showSuccessModal = false;
//     // @track successRecordCount = 0;

//     // // Close success modal
//     // closeSuccessModal() {
//     //     this.showSuccessModal = false;
//     // }

//     // Getters for object type
//     get isIOSObject() {
//         return this.selectedObject === 'iOS_and_Android_App_Details__c';
//     }

//     get isContactObject() {
//         return this.selectedObject === 'Contact';
//     }

//     get selectedObjectLabel() {
//         const obj = this.objectOptions.find(opt => opt.value === this.selectedObject);
//         return obj ? obj.label : this.selectedObject;
//     }

//     get visibleRecords() {
//         return this.filteredRecords.slice(0, this.loadedCount);
//     }

//     get visibleRecordsWithRowNumber() {
//         return this.visibleRecords.map((record, idx) => ({
//             ...record,
//             rowNumber: idx + 1
//         }));
//     }

//     get totalRecords() {
//         return this.totalSize;
//     }

//     get selectedCount() {
//         return this.selectedRecords.length;
//     }

//     get isPushDisabled() {
//         return this.selectedCount === 0;
//     }

//     get isPollFormValid() {
//         const filledOptions = this.pollOptions.filter(opt => opt.value.trim() !== '');
//         return (
//             !this.pollQuestion.trim() ||
//             filledOptions.length < 2 ||
//             !this.pollEndDate ||
//             !this.pollEndTime
//         );
//     }

//     get isAddOptionDisabled() {
//         return this.pollOptions.length >= 5;
//     }

//     // Log selected IDs for debugging
//     logSelectedIds() {
//         console.log('Selected IDs:', this.selectedRecords);
//         console.log('Selected Object:', this.selectedObject);
//     }

//     // Handle object selection change

//     handleObjectChange(event) {
//         this.selectedObject = event.detail.value;
//         this.isLoading = true;
//         this.loadedCount = 500;
//         this.offset = 0;
//         this.limit = 500;
//         this.filterCriteria = [];
//         this.appliedCustomLogic = '';  // ✅ FIX: Reset custom logic  // Add this line for dynamic filters
//         this.customFilterLogic = '';     // ✅ ADD: Reset input field
//         this.resetSelectionState();

//         // Reset poll data when changing the object type
//         this.storedPollData = null;
//         this.pollButtonLabel = 'Add Poll';
//         this.pollQuestionId = null;

//         this._scrollHandlerAttached = false;
//         this.wiredDataResult = null;
//         console.log('Object changed to:', this.selectedObject);
//     }


//     // Fetch data for the selected object
//     @wire(getFieldDescriptionsAndRecords, {
//         objectName: '$selectedObject',
//         filters: '$filterCriteria',
//         customLogic: '$appliedCustomLogic',  // Add this line for dynamic filters
//         offset: '$offset',
//         recordLimit: '$limit'
//     })
//     wiredData(result) {
//         this.wiredDataResult = result;
//         if (result.data || result.error) {
//             this.isLoading = false;
//         }
//         if (result.data) {
//             const data = result.data;
//             this.totalSize = data.totalSize;
//             this.fieldOptions = data.fieldDescriptions
//                 .map(field => ({
//                     label: field.label,
//                     value: field.value,
//                     picklistValues: field.picklistValues
//                 }))
//                 .sort((a, b) => a.label.localeCompare(b.label));

//             // Append new records to the existing list
//             let newRecords = data.records.map(record => ({
//                 ...record,
//                 isSelected: this.selectedRecords.includes(record.Id)
//             }));

//             if (this.offset === 0) {
//                 this.records = newRecords;
//             } else {
//                 this.records = [...this.records, ...newRecords];
//             }

//             this.filteredRecords = [...this.records];
//             this.applyFilters();
//         } else if (result.error) {
//             console.error('Error loading data', result.error);
//         }
//     }

//     // Load more records on scroll
//     renderedCallback() {
//         if (!this._scrollHandlerAttached) {
//             const tableContainer = this.template.querySelector('.slds-table_container');
//             if (tableContainer) {
//                 tableContainer.addEventListener('scroll', this.handleTableScroll.bind(this));
//                 this._scrollHandlerAttached = true;
//             }
//         }
//     }

//     // Modify handleCustomFilterLogicChange to only update the value // Add this for dynamic filters
//     handleCustomFilterLogicChange(event) {
//         this.customFilterLogic = event.target.value;
//     }

//     handleTableScroll(event) {
//         const container = event.target;
//         if (container.scrollTop + container.clientHeight >= container.scrollHeight - 100 &&
//             this.loadedCount < this.totalSize &&
//             !this.isLoadingMore) {
//             this.loadMoreRecords();
//         }
//     }

//     async loadMoreRecords() {
//         this.isLoadingMore = true;
//         this.offset += this.limit;

//         // Wait for the data to load
//         await new Promise(resolve => setTimeout(resolve, 300));

//         // After new records are loaded, update the UI to reflect selected records
//         this.records = this.records.map(record => ({
//             ...record,
//             isSelected: this.selectedRecords.includes(record.Id)
//         }));

//         this.filteredRecords = this.filteredRecords.map(record => ({
//             ...record,
//             isSelected: this.selectedRecords.includes(record.Id)
//         }));

//         this.loadedCount = this.records.length;
//         this.isLoadingMore = false;
//     }

//     resetSelectionState() {
//         this.selectAll = false;
//         this.selectedRecords = [];
//         this.records = this.records.map(record => ({
//             ...record,
//             isSelected: false
//         }));
//         this.filteredRecords = this.filteredRecords.map(record => ({
//             ...record,
//             isSelected: false
//         }));
//     }

//     // Filter panel handlers
//     openFilterPanel() {
//         this.showFilterPanel = true;
//     }

//     closeFilterPanel() {
//         this.showFilterPanel = false;
//     }

//     addFilter() {
//         this.editingFilter = { field: '', operator: '=', value: '', valueOptions: [] };
//         this.editingIndex = this.filterCriteria.length;
//         this.showFilterEditModal = true;
//         this.appliedCustomLogic = ''; // Add this line for dynamic filters
//         this.resetSelectionState(); // Reset selection state when a new filter is added
//     }

//     editFilter(event) {
//         const index = event.target.dataset.index;
//         const filter = this.filterCriteria[index];
//         this.editingFilter = { ...filter };
//         this.editingIndex = index;
//         this.showFilterEditModal = true;
//     }

//     closeEditFilterModal() {
//         this.showFilterEditModal = false;
//         this.editingFilter = { field: '', operator: '=', value: '', valueOptions: [] };
//         this.editingIndex = null;
//     }

//     handleEditFilterChange(event) {
//         const { name, value } = event.target;
//         let editingFilter = { ...this.editingFilter, [name]: value };
//         if (name === 'field') {
//             const selectedField = this.fieldOptions.find(option => option.value === value);
//             if (selectedField && selectedField.picklistValues) {
//                 editingFilter.valueOptions = selectedField.picklistValues.map(item => ({ label: item, value: item }));
//             } else {
//                 editingFilter.valueOptions = undefined;
//             }
//             editingFilter.value = '';
//             editingFilter.fieldLabel = selectedField ? selectedField.label : 'New Filter';
//         }
//         this.editingFilter = editingFilter;
//     }

//     saveEditFilter() {
//         let filter = { ...this.editingFilter };
//         if (!filter.fieldLabel) {
//             const selectedField = this.fieldOptions.find(option => option.value === filter.field);
//             filter.fieldLabel = selectedField ? selectedField.label : 'New Filter';
//         }
//         let criteria = [...this.filterCriteria];
//         criteria[this.editingIndex] = filter;
//         this.filterCriteria = criteria;
//         this.appliedCustomLogic = '';  // Add this line for dynamic filters
//         this.showFilterEditModal = false;
//         this.editingIndex = null;
//         this.resetSelectionState(); // Reset selection state when a filter is edited
//         this.applyFilters();
//     }

//     handlePopoverBackgroundClick(event) {
//         if (event.target === this.template.querySelector('.filter-popover-anchor')) {
//             this.closeEditFilterModal();
//         }
//     }

//     removeAllFilters() {
//         this.filterCriteria = [];
//         this.appliedCustomLogic = '';  // Add this line for dynamic filters
//         this.customFilterLogic = '';     // ✅ ADD: Reset input field
//         this.resetSelectionState(); // Reset selection state when all filters are removed
//         this.applyFilters();
//     }

//     removeFilter(event) {
//         const index = event.target.dataset.index;
//         this.filterCriteria = this.filterCriteria.filter((_, i) => i != index);
//         this.appliedCustomLogic = '';  // Add this line for dynamic filters
//         this.resetSelectionState(); // Reset selection state when a filter is removed
//         this.applyFilters();
//     }

//     // applyFilters() {
//     //     console.log('Applying filters...');
//     //     this.filteredRecords = this.filterRecords(this.records);
//     //     this.syncSelectedRecords();

//     //     // Update selectAll state based on whether all visible records are selected
//     //     const visibleIds = this.visibleRecords.map(r => r.Id);
//     //     this.selectAll = visibleIds.length > 0 && visibleIds.every(id => this.selectedRecords.includes(id));
//     // }


//     // 2. ✅ Your applyFilters() - KEEP EXACTLY AS IS:     // Add this for dynamic filters
//     applyFilters() {
//         console.log('Applying filters...');
//         console.log('Filter Criteria:', JSON.stringify(this.filterCriteria));
//         console.log('Custom Logic:', this.customLogic);
//         this.filteredRecords = [...this.records];
//         this.syncSelectedRecords();

//         // Update selectAll state based on whether all visible records are selected
//         const visibleIds = this.visibleRecords.map(r => r.Id);
//         this.selectAll = visibleIds.length > 0 && visibleIds.every(id => this.selectedRecords.includes(id));
//     }

//     // Add this for dynamic filters
//     get showCustomFilterLogic() {
//         return this.filterCriteria.length > 1;
//     }

//     getNestedValue(obj, path) {
//         return path.split('.').reduce((acc, part) => acc && acc[part], obj);
//     }

//     filterRecords(records) {
//         if (this.filterCriteria.length > 0) {
//             return records.filter(record => {
//                 return this.filterCriteria.every(filter => {
//                     const fieldValue = this.getNestedValue(record, filter.field);
//                     return this.applyFilterCondition(fieldValue, filter);
//                 });
//             });
//         }
//         return records;
//     }

//     applyFilterCondition(fieldValue, filter) {
//         const filterValues = filter.value.split(',').map(v => v.trim().toUpperCase());
//         const fieldValueStr = String(fieldValue).toUpperCase();
//         switch (filter.operator) {
//             case OPERATORS.EQUALS:
//                 return filterValues.includes(fieldValueStr);
//             case OPERATORS.NOT_EQUAL:
//                 return !filterValues.includes(fieldValueStr);
//             case OPERATORS.LESS_THAN:
//                 return filterValues.some(val => fieldValueStr < val);
//             case OPERATORS.GREATER_THAN:
//                 return filterValues.some(val => fieldValueStr > val);
//             case OPERATORS.LESS_OR_EQUAL:
//                 return filterValues.some(val => fieldValueStr <= val);
//             case OPERATORS.GREATER_OR_EQUAL:
//                 return filterValues.some(val => fieldValueStr >= val);
//             case OPERATORS.CONTAINS:
//                 return filterValues.some(val => fieldValueStr.includes(val));
//             case OPERATORS.NOT_CONTAINS:
//                 return !filterValues.some(val => fieldValueStr.includes(val));
//             case OPERATORS.STARTS_WITH:
//                 return filterValues.some(val => fieldValueStr.startsWith(val));
//             default:
//                 return true;
//         }
//     }

//     syncSelectedRecords() {
//         const filteredIds = this.filteredRecords.map(r => r.Id);
//         this.selectedRecords = this.selectedRecords.filter(id => filteredIds.includes(id));
//     }

//     // Toggle select all
//     async toggleSelectAll(event) {
//         const isChecked = event.target.checked;
//         const visibleIds = this.visibleRecords.map(r => r.Id);

//         if (visibleIds.length === 0) {
//             this.selectAll = false;
//             return;
//         }

//         this.selectAll = isChecked;
//         if (isChecked) {
//             this.isLoading = true;
//             try {
//                 const allIds = await getAllRecordIds({
//                     objectName: this.selectedObject,
//                     filters: this.filterCriteria,
//                     customLogic: this.appliedCustomLogic  // Add this line for dynamic filters
//                 });
//                 this.selectedRecords = [...new Set(allIds)];

//                 // Update the UI to reflect selected records
//                 this.records = this.records.map(record => ({
//                     ...record,
//                     isSelected: allIds.includes(record.Id)
//                 }));

//                 this.filteredRecords = this.filteredRecords.map(record => ({
//                     ...record,
//                     isSelected: allIds.includes(record.Id)
//                 }));

//                 this.dispatchEvent(
//                     new ShowToastEvent({
//                         title: 'Success',
//                         message: `All ${this.totalSize} records selected!`,
//                         variant: 'success'
//                     })
//                 );
//             } catch (error) {
//                 console.error('Error fetching all record IDs:', error);
//             } finally {
//                 this.isLoading = false;
//                 this.logSelectedIds();
//             }
//         } else {
//             // Only remove the visible records from selectedRecords
//             this.selectedRecords = this.selectedRecords.filter(id => !visibleIds.includes(id));

//             // Update the UI to reflect unselected records
//             this.records = this.records.map(record => ({
//                 ...record,
//                 isSelected: this.selectedRecords.includes(record.Id)
//             }));

//             this.filteredRecords = this.filteredRecords.map(record => ({
//                 ...record,
//                 isSelected: this.selectedRecords.includes(record.Id)
//             }));
//         }
//     }

//     // Handle checkbox selection
//     handleCheckbox(event) {
//         const recordId = event.target.dataset.id;
//         const isChecked = event.target.checked;

//         this.records = this.records.map(record => {
//             if (record.Id === recordId) {
//                 return { ...record, isSelected: isChecked };
//             }
//             return record;
//         });

//         this.filteredRecords = this.filteredRecords.map(record => {
//             if (record.Id === recordId) {
//                 return { ...record, isSelected: isChecked };
//             }
//             return record;
//         });

//         if (isChecked) {
//             if (!this.selectedRecords.includes(recordId)) {
//                 this.selectedRecords = [...this.selectedRecords, recordId];
//             }
//         } else {
//             this.selectedRecords = this.selectedRecords.filter(id => id !== recordId);
//         }

//         const visibleIds = this.visibleRecords.map(r => r.Id);
//         this.selectAll = visibleIds.every(id => this.selectedRecords.includes(id));
//         this.logSelectedIds();
//     }

//     // Navigation handlers
//     handleSchoolNameClick(event) {
//         if (!this.isIOSObject) return;
//         const recordId = event.currentTarget.dataset.recordId;
//         this[NavigationMixin.Navigate]({
//             type: 'standard__recordPage',
//             attributes: {
//                 recordId: recordId,
//                 objectApiName: 'School_App__c',
//                 actionName: 'view'
//             }
//         });
//     }

//     handleAccountClick(event) {
//         const accountId = event.currentTarget.dataset.id;
//         this[NavigationMixin.Navigate]({
//             type: 'standard__recordPage',
//             attributes: {
//                 recordId: accountId,
//                 objectApiName: 'Account',
//                 actionName: 'view'
//             }
//         });
//     }

//     // Modify saveCustomFilterLogic to apply the custom logic   // Add this for dynamic filters
//     saveCustomFilterLogic() {
//         console.log('saveCustomFilterLogic called');
//         if (!this.customFilterLogic) {
//             this.dispatchEvent(
//                 new ShowToastEvent({
//                     title: 'Error',
//                     message: 'Please enter custom filter logic!',
//                     variant: 'error'
//                 })
//             );
//             return;
//         }

//         // Set the applied custom logic to trigger the wire method
//         this.appliedCustomLogic = this.customFilterLogic;

//         // Reset the wire adapter to refresh data with the new custom logic
//         this.wiredDataResult = null;

//         this.dispatchEvent(
//             new ShowToastEvent({
//                 title: 'Success',
//                 message: 'Custom filter logic applied!',
//                 variant: 'success'
//             })
//         );
//     }

//     // iOS/Android Notification Modal Handlers
//     openNotificationModal() {
//         if (this.isIOSObject) {
//             console.log('Opening iOS/Android Notification Modal');
//             this.showIOSNotificationModal = true;
//         } else if (this.isContactObject) {
//             console.log('Opening Contact Notification Modal');
//             this.showContactNotificationModal = true;
//         }
//         this.logSelectedIds();
//     }

//     closeIOSNotificationModal() {
//         this.showIOSNotificationModal = false;
//         this.isIOSModalLoading = false;
//         this.iosNotificationTitle = '';
//         this.iosNotificationBody = '';
//         this.iosNotificationImageUrl = '';
//         this.iosNotificationLaunchUrl = '';
//         this.iosScheduledDate = '';
//         this.iosScheduledTime = '';
//         this.iosIsPinChecked = false;
//         this.iosPinEndDate = '';

//         // Reset poll data when closing the modal
//         this.storedPollData = null;
//         this.pollButtonLabel = 'Add Poll';
//         this.pollQuestionId = null;
//     }

//     handleIOSTitleChange(event) {
//         this.iosNotificationTitle = event.target.value;
//     }

//     handleIOSBodyChange(event) {
//         this.iosNotificationBody = event.target.value;
//     }

//     handleIOSImageUrlChange(event) {
//         this.iosNotificationImageUrl = event.target.value;
//     }

//     handleIOSLaunchUrlChange(event) {
//         this.iosNotificationLaunchUrl = event.target.value;
//     }

//     handleIOSScheduledDateChange(event) {
//         this.iosScheduledDate = event.target.value;
//     }

//     handleIOSScheduledTimeChange(event) {
//         this.iosScheduledTime = event.target.value;
//     }

//     handleIOSPinCheckboxChange(event) {
//         this.iosIsPinChecked = event.target.checked;
//     }

//     // Add this method to handle changes to the pin end date
//     handleIOSPinEndDateChange(event) {
//         this.iosPinEndDate = event.target.value;
//         console.log('Pin End Date selected:', this.iosPinEndDate);
//     }

//     closeContactNotificationModal() {
//         this.showContactNotificationModal = false;
//         this.isContactModalLoading = false;
//         this.contactNotificationTitle = '';
//         this.contactNotificationBody = '';
//         this.contactNotificationImageUrl = '';
//         this.contactNotificationLaunchUrl = '';
//     }


//     handleContactTitleChange(event) {
//         this.contactNotificationTitle = event.target.value;
//     }

//     handleContactBodyChange(event) {
//         this.contactNotificationBody = event.target.value;
//     }

//     handleContactImageUrlChange(event) {
//         this.contactNotificationImageUrl = event.target.value;
//     }

//     handleContactLaunchUrlChange(event) {
//         this.contactNotificationLaunchUrl = event.target.value;
//     }

//     openIOSPollModal() {
//         this.showIOSPollModal = true;

//         // Pre-fill the poll modal if stored data exists
//         if (this.storedPollData) {
//             this.pollQuestion = this.storedPollData.question;
//             this.pollOptions = this.storedPollData.options.map((option, index) => ({
//                 id: `option-${index + 1}`,
//                 value: option,
//                 placeholder: `Enter option ${index + 1}`,
//                 isRequired: true,
//                 canDelete: index >= 2
//             }));
//             this.pollEndDate = this.storedPollData.endDate;
//             this.pollEndTime = this.storedPollData.endTime;
//         } else {
//             // Reset to default if no stored data
//             this.pollQuestion = '';
//             this.pollOptions = [
//                 { id: 'option-1', value: '', placeholder: 'Enter option 1', isRequired: true },
//                 { id: 'option-2', value: '', placeholder: 'Enter option 2', isRequired: true }
//             ];
//             this.pollEndDate = '';
//             this.pollEndTime = '';
//         }
//     }

//     closeIOSPollModal() {
//         this.showIOSPollModal = false;
//         this.pollQuestion = '';
//         this.pollOptions = [
//             { id: 'option-1', value: '', placeholder: 'Enter option 1' },
//             { id: 'option-2', value: '', placeholder: 'Enter option 2' }
//         ];
//         this.nextPollOptionId = 3;
//         this.pollEndDate = '';
//         this.pollEndTime = '';
//     }

//     handlePollQuestionChange(event) {
//         this.pollQuestion = event.target.value;
//     }

//     handlePollOptionChange(event) {
//         const index = parseInt(event.target.dataset.index);
//         const newOptions = [...this.pollOptions];
//         newOptions[index].value = event.target.value;
//         this.pollOptions = newOptions;
//     }

//     addPollOption() {
//         if (this.pollOptions.length < 5) {
//             const newOption = {
//                 id: `option-${this.nextPollOptionId}`,
//                 value: '',
//                 placeholder: `Enter option ${this.nextPollOptionId}`,
//                 isRequired: false,
//                 canDelete: true
//             };
//             this.pollOptions = [...this.pollOptions, newOption];
//             this.nextPollOptionId++;
//         }
//     }

//     removePollOption(event) {
//         const index = parseInt(event.target.dataset.index);
//         if (this.pollOptions.length > 2) {
//             this.pollOptions = this.pollOptions.filter((_, i) => i !== index);
//         } else {
//             this.dispatchEvent(
//                 new ShowToastEvent({
//                     title: 'Error',
//                     message: 'At least 2 options are required!',
//                     variant: 'error'
//                 })
//             );
//         }
//     }

//     handlePollEndDateChange(event) {
//         this.pollEndDate = event.target.value;
//     }

//     handlePollEndTimeChange(event) {
//         this.pollEndTime = event.target.value;
//     }

//     // Save Poll (API call)
//     savePoll() {
//         const options = this.pollOptions
//             .map((opt, index) => ({
//                 Poll_Option: opt.value,
//                 Sort_Order: index,
//                 Active_Status: "true"
//             }))
//             .filter(opt => opt.Poll_Option.trim() !== '');

//         if (options.length < 2) {
//             this.dispatchEvent(
//                 new ShowToastEvent({
//                     title: 'Error',
//                     message: 'Please provide at least 2 poll options!',
//                     variant: 'error'
//                 })
//             );
//             return;
//         }

//         const pollData = {
//             Account_Id: "0014W00002aAD6wQAG",
//             Poll_Question: this.pollQuestion,
//             Poll_Start_Date: new Date().toISOString().split('T')[0],
//             Poll_Start_Time: new Date().toISOString().split('T')[1].split('.')[0],
//             Poll_End_Date: this.pollEndDate,
//             Poll_End_Time: this.pollEndTime,
//             Active_Status: "true",
//             Poll_Options: options
//         };

//         this.isIOSModalLoading = true;

//         fetch('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/poll', {
//             method: 'POST',
//             headers: {
//                 'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlYWNoZXIuc29sdmVkQHN5c3RlbS51c2VyIiwicm9sZSI6InRlYWNoZXIiLCJpZCI6IjAwM052MDAwMDBKQXk4MUlBRCIsImlhdCI6MTczMzQwNjAyNn0.Hnkzas3BJpT2bjeUAtMSNJxgaIdxBlebp29YlmgOoFU',
//                 'Content-Type': 'application/json'
//             },
//             body: JSON.stringify(pollData)
//         })
//             .then(response => {
//                 if (!response.ok) {
//                     throw new Error(`Failed to save poll: ${response.status} ${response.statusText}`);
//                 }
//                 return response.json();
//             })
//             .then(data => {
//                 this.dispatchEvent(
//                     new ShowToastEvent({
//                         title: '🎉 Success!',
//                         message: 'Poll saved successfully!',
//                         variant: 'success'
//                     })
//                 );
//                 this.pollQuestionId = data.body.Poll_Question.Id;

//                 // Store the poll data for editing
//                 this.storedPollData = {
//                     question: this.pollQuestion,
//                     options: this.pollOptions.map(opt => opt.value),
//                     endDate: this.pollEndDate,
//                     endTime: this.pollEndTime
//                 };

//                 this.pollButtonLabel = 'Edit Poll';
//                 this.closeIOSPollModal();
//             })
//             .catch(error => {
//                 console.error('Error saving poll:', error);
//                 this.dispatchEvent(
//                     new ShowToastEvent({
//                         title: 'Error',
//                         message: error.message,
//                         variant: 'error'
//                     })
//                 );
//             })
//             .finally(() => {
//                 this.isIOSModalLoading = false;
//             });
//     }

//     // Send iOS/Android Notification
//     // sendIOSNotification() {
//     //     if (!this.iosNotificationTitle || !this.iosNotificationBody) {
//     //         this.dispatchEvent(
//     //             new ShowToastEvent({
//     //                 title: 'Error',
//     //                 message: 'Title and Message are required!',
//     //                 variant: 'error'
//     //             })
//     //         );
//     //         return;
//     //     }
//     //     // First confirmation
//     //     const firstConfirm = confirm('Are you sure you want to send this Push Notification to all the selected Schools?');
//     //     if (!firstConfirm) return;

//     //     // Second confirmation
//     //     const secondConfirm = confirm('You cannot undo this action. Continue?');
//     //     if (!secondConfirm) return;

//     //     const requestBody = {
//     //         ids: this.selectedRecords,
//     //         title: this.iosNotificationTitle,
//     //         message: this.iosNotificationBody,
//     //         imageUrl: this.iosNotificationImageUrl,
//     //         url: this.iosNotificationLaunchUrl,
//     //         scheduleDate: this.iosScheduledDate,
//     //         scheduleTime: this.iosScheduledTime,
//     //         pinned: this.iosIsPinChecked,
//     //         pollQuestionId: this.pollQuestionId,
//     //         pinEndDate: this.iosPinEndDate,
//     //     };

//     //     console.log('Request Body for iOS Notification:', JSON.stringify(requestBody));

//     //     this.isIOSModalLoading = true;
//     //     this.isLoading = true;

//     //     fetch('https://9nwyf9euuf.execute-api.us-east-2.amazonaws.com/prod/send-mass-push-notifications', {
//     //         method: 'POST',
//     //         headers: {
//     //             'Authorization': 'r?ftDEZ_qdt=VjD#W@S2LM8FZT97Nx',
//     //             'Content-Type': 'application/json',
//     //         },
//     //         body: JSON.stringify(requestBody),
//     //     })
//     //         .then(async response => {
//     //             this.isLoading = false;
//     //             const data = await response.json();
//     //             console.log('Response Data :', data);
//     //             if (response.ok) {
//     //                 this.dispatchEvent(
//     //                     new ShowToastEvent({
//     //                         title: '🎉 Success!',
//     //                         message: `Notification sent to ${this.selectedRecords.length} schools!`,
//     //                         variant: 'success'
//     //                     })
//     //                 );

//     //                 //    if (response.ok) {
//     //                 // this.successRecordCount = this.selectedRecords.length;
//     //                 // this.showSuccessModal = true;

//     //                 // Reset poll data after sending the push message
//     //                 this.storedPollData = null;
//     //                 this.pollButtonLabel = 'Add Poll';
//     //                 this.pollQuestionId = null;

//     //                 this.closeIOSNotificationModal();
//     //                 // Refresh the page after success
//     //                 // window.location.reload();
//     //             } else {
//     //                 this.isIOSModalLoading = false;
//     //                 throw new Error(`Failed: ${response.status} ${response.statusText}`);
//     //             }
//     //         })
//     //         .catch(error => {
//     //             this.isLoading = false;
//     //             this.isIOSModalLoading = false;
//     //             this.dispatchEvent(
//     //                 new ShowToastEvent({
//     //                     title: 'Error',
//     //                     message: error.message,
//     //                     variant: 'error'
//     //                 })
//     //             );
//     //         });
//     // }

//     sendIOSNotification() {
//         if (!this.iosNotificationTitle || !this.iosNotificationBody) {
//             this.dispatchEvent(
//                 new ShowToastEvent({
//                     title: 'Error',
//                     message: 'Title and Message are required!',
//                     variant: 'error'
//                 })
//             );
//             return;
//         }

//         // First confirmation
//         const firstConfirm = confirm('Are you sure you want to send this Push Notification to all the selected Schools?');
//         if (!firstConfirm) return;

//         // Second confirmation
//         const secondConfirm = confirm('You cannot undo this action. Continue?');
//         if (!secondConfirm) return;

//         // Append the invisible emoji to title and message
//         const titleWithEmoji = this.iosNotificationTitle + 'ㅤ';
//         const messageWithEmoji = this.iosNotificationBody + 'ㅤ';

//         const requestBody = {
//             ids: this.selectedRecords,
//             title: titleWithEmoji,
//             message: messageWithEmoji,
//             imageUrl: this.iosNotificationImageUrl,
//             url: this.iosNotificationLaunchUrl,
//             scheduleDate: this.iosScheduledDate,
//             scheduleTime: this.iosScheduledTime,
//             pinned: this.iosIsPinChecked,
//             pollQuestionId: this.pollQuestionId,
//             pinEndDate: this.iosPinEndDate,
//         };

//         console.log('Request Body for iOS Notification:', JSON.stringify(requestBody));

//         this.isIOSModalLoading = true;
//         this.isLoading = true;

//         fetch('https://9nwyf9euuf.execute-api.us-east-2.amazonaws.com/prod/send-mass-push-notifications', {
//             method: 'POST',
//             headers: {
//                 'Authorization': 'r?ftDEZ_qdt=VjD#W@S2LM8FZT97Nx',
//                 'Content-Type': 'application/json',
//             },
//             body: JSON.stringify(requestBody),
//         })
//             .then(async response => {
//                 this.isLoading = false;
//                 const data = await response.json();
//                 console.log('Response Data :', data);
//                 if (response.ok) {
//                     this.dispatchEvent(
//                         new ShowToastEvent({
//                             title: '🎉 Success!',
//                             message: `Notification sent to ${this.selectedRecords.length} schools!`,
//                             variant: 'success'
//                         })
//                     );

//                     // Reset poll data after sending the push message
//                     this.storedPollData = null;
//                     this.pollButtonLabel = 'Add Poll';
//                     this.pollQuestionId = null;

//                     this.closeIOSNotificationModal();
//                 } else {
//                     this.isIOSModalLoading = false;
//                     throw new Error(`Failed: ${response.status} ${response.statusText}`);
//                 }
//             })
//             .catch(error => {
//                 this.isLoading = false;
//                 this.isIOSModalLoading = false;
//                 this.dispatchEvent(
//                     new ShowToastEvent({
//                         title: 'Error',
//                         message: error.message,
//                         variant: 'error'
//                     })
//                 );
//             });
//     }


//     // Send Contact Notification
//     sendContactNotification() {
//         if (!this.contactNotificationTitle || !this.contactNotificationBody) {
//             this.dispatchEvent(
//                 new ShowToastEvent({
//                     title: 'Error',
//                     message: 'Title and Message are required!',
//                     variant: 'error'
//                 })
//             );
//             return;
//         }

//         // First confirmation
//         const firstConfirm = confirm('Are you sure you want to send this Push Notification to all the selected Schools?');
//         if (!firstConfirm) return;

//         // Second confirmation
//         const secondConfirm = confirm('You cannot undo this action. Continue?');
//         if (!secondConfirm) return;

//         const attachments = this.contactNotificationImageUrl ? [{
//             sort_order: 0,
//             url: this.contactNotificationImageUrl
//         }] : [];

//         const requestBody = {
//             IsStaff_Story: true,
//             title: this.contactNotificationTitle,
//             message: this.contactNotificationBody,
//             attachments: attachments,
//             launch_url: this.contactNotificationLaunchUrl,
//             Story_Recepients: this.selectedRecords.map(id => ({
//                 Teacher_Id: id
//             }))
//         };

//         console.log('Request Body for Contacts:', JSON.stringify(requestBody));

//         this.isContactModalLoading = true;
//         this.isLoading = true;

//         fetch('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-and-social-feed/staff-story', {
//             method: 'POST',
//             headers: {
//                 'Content-Type': 'application/json'
//             },
//             body: JSON.stringify(requestBody)
//         })
//             .then(async response => {
//                 this.isLoading = false;
//                 const data = await response.json();
//                 console.log('Response Data:', data);
//                 if (response.ok && (!data.statusCode || data.statusCode === 200)) {
//                     // Only show success if the response body does NOT contain an error
//                     this.dispatchEvent(
//                         new ShowToastEvent({
//                             title: '🎉 Success!',
//                             message: `Notification sent to ${this.selectedRecords.length} staff members!`,
//                             variant: 'success'
//                         })
//                     );
//                     this.closeContactNotificationModal();
//                 } else {
//                     // Show error if the response body contains an error
//                     throw new Error(data.message || `Failed: ${response.status} ${response.statusText}`);
//                 }
//             })
//             .catch(error => {
//                 this.isLoading = false;
//                 this.isContactModalLoading = false;
//                 console.error('Error:', error);
//                 this.dispatchEvent(
//                     new ShowToastEvent({
//                         title: 'Error',
//                         message: error.message,
//                         variant: 'error'
//                     })
//                 );
//             });
//     }

// }


// // testing code for student and parent also

import { LightningElement, track, wire } from 'lwc';
import getFieldDescriptionsAndRecords from '@salesforce/apex/MassPushNotificationController.getFieldDescriptionsAndRecords';
import getAllRecordIds from '@salesforce/apex/MassPushNotificationController.getAllRecordIds';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Constants for operators
const OPERATORS = {
    EQUALS: '=',
    NOT_EQUAL: '!=',
    LESS_THAN: '<',
    GREATER_THAN: '>',
    LESS_OR_EQUAL: '<=',
    GREATER_OR_EQUAL: '>=',
    CONTAINS: 'LIKE',
    NOT_CONTAINS: 'NOT LIKE',
    STARTS_WITH: 'STARTS WITH'
};

// Object options for dropdown
const OBJECT_OPTIONS = [
    { label: 'Schools', value: 'iOS_and_Android_App_Details__c' },
    { label: 'Staff', value: 'Contact' },
    { label: 'Students', value: 'Student__c' },           // ✅ NEW
    { label: 'Parents', value: 'Student_Parent_Relationship__c' }  // ✅ NEW
];

export default class MassPushNotification extends NavigationMixin(LightningElement) {
    // Existing tracked properties
    @track selectedObject = 'iOS_and_Android_App_Details__c';
    @track objectOptions = OBJECT_OPTIONS;
    @track records = [];
    @track filteredRecords = [];
    @track selectedRecords = [];
    @track selectAll = false;
    @track filterCriteria = [];
    @track fieldOptions = [];
    @track operatorOptions = [
        { label: 'equals', value: OPERATORS.EQUALS },
        { label: 'not equal to', value: OPERATORS.NOT_EQUAL },
        { label: 'less than', value: OPERATORS.LESS_THAN },
        { label: 'greater than', value: OPERATORS.GREATER_THAN },
        { label: 'less or equal', value: OPERATORS.LESS_OR_EQUAL },
        { label: 'greater or equal', value: OPERATORS.GREATER_OR_EQUAL },
        { label: 'contains', value: OPERATORS.CONTAINS },
        { label: 'does not contain', value: OPERATORS.NOT_CONTAINS },
        { label: 'starts with', value: OPERATORS.STARTS_WITH }
    ];
    @track showFilterPanel = false;
    @track showFilterEditModal = false;
    @track editingFilter = { field: '', operator: '=', value: '', valueOptions: [] };
    @track editingIndex = null;
    @track isLoading = true;
    @track loadedCount = 500;
    @track isLoadingMore = false;
    @track noRecordsFound = false;
    @track wiredDataResult;
    @track totalSize = 0;
    @track offset = 0;
    @track limit = 500;

    // iOS/Android Notification Modal properties
    @track showIOSNotificationModal = false;
    @track iosNotificationTitle = '';
    @track iosNotificationBody = '';
    @track iosNotificationImageUrl = '';
    @track iosNotificationLaunchUrl = '';
    @track iosScheduledDate = '';
    @track iosScheduledTime = '';
    @track iosIsPinChecked = false;

    // Contact Notification Modal properties
    @track showContactNotificationModal = false;
    @track contactNotificationTitle = '';
    @track contactNotificationBody = '';
    @track contactNotificationImageUrl = '';
    @track contactNotificationLaunchUrl = '';

    // Student Modal - SIMPLE (like Contact)
    @track showStudentNotificationModal = false;
    @track studentNotificationTitle = '';
    @track studentNotificationBody = '';
    @track studentNotificationImageUrl = '';
    @track isStudentModalLoading = false;

    // Parent Modal - SIMPLE (like Contact)  
    @track showParentNotificationModal = false;
    @track parentNotificationTitle = '';
    @track parentNotificationBody = '';
    @track parentNotificationImageUrl = '';
    @track isParentModalLoading = false;


    // Poll Modal properties
    @track showIOSPollModal = false;
    @track pollQuestion = '';
    @track pollOptions = [
        { id: 'option-1', value: '', placeholder: 'Enter option 1', isRequired: true },
        { id: 'option-2', value: '', placeholder: 'Enter option 2', isRequired: true }
    ];

    @track pollEndDate = '';
    @track pollEndTime = '';
    @track pollQuestionId = null;
    @track nextPollOptionId = 3;

    // Spinner properties
    @track isIOSModalLoading = false;
    @track isContactModalLoading = false;

    @track iosPinEndDate = '';

    @track pollButtonLabel = 'Add Poll'; // Add this line

    @track storedPollData = null;

    @track appliedCustomLogic = '';    // Add this line for dynamic filters
    @track customFilterLogic = '';     // Add this line for dynamic filters

    // commented code for sucess PopUp

    // @track showSuccessModal = false;
    // @track successRecordCount = 0;

    // // Close success modal
    // closeSuccessModal() {
    //     this.showSuccessModal = false;
    // }

    // Getters for object type
    get isIOSObject() {
        return this.selectedObject === 'iOS_and_Android_App_Details__c';
    }

    get isContactObject() {
        return this.selectedObject === 'Contact';
    }

    get selectedObjectLabel() {
        const obj = this.objectOptions.find(opt => opt.value === this.selectedObject);
        return obj ? obj.label : this.selectedObject;
    }

    get visibleRecords() {
        return this.filteredRecords.slice(0, this.loadedCount);
    }

    get visibleRecordsWithRowNumber() {
        return this.visibleRecords.map((record, idx) => ({
            ...record,
            rowNumber: idx + 1
        }));
    }

    get totalRecords() {
        return this.totalSize;
    }

    get selectedCount() {
        return this.selectedRecords.length;
    }

    get isPushDisabled() {
        return this.selectedCount === 0;
    }

    get isPollFormValid() {
        const filledOptions = this.pollOptions.filter(opt => opt.value.trim() !== '');
        return (
            !this.pollQuestion.trim() ||
            filledOptions.length < 2 ||
            !this.pollEndDate ||
            !this.pollEndTime
        );
    }

    get isAddOptionDisabled() {
        return this.pollOptions.length >= 5;
    }

    get isStudentObject() {
        return this.selectedObject === 'Student__c';
    }

    get isParentObject() {
        return this.selectedObject === 'Student_Parent_Relationship__c';
    }

    // Log selected IDs for debugging
    logSelectedIds() {
        console.log('Selected IDs:', this.selectedRecords);
        console.log('Selected Object:', this.selectedObject);
    }

    // Handle object selection change

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.isLoading = true;
        this.loadedCount = 500;
        this.offset = 0;
        this.limit = 500;
        this.filterCriteria = [];
        this.appliedCustomLogic = '';  // ✅ FIX: Reset custom logic  // Add this line for dynamic filters
        this.customFilterLogic = '';     // ✅ ADD: Reset input field
        this.resetSelectionState();

        // Reset poll data when changing the object type
        this.storedPollData = null;
        this.pollButtonLabel = 'Add Poll';
        this.pollQuestionId = null;

        this._scrollHandlerAttached = false;
        this.wiredDataResult = null;
        console.log('Object changed to:', this.selectedObject);
    }

    // Fetch data for the selected object
    @wire(getFieldDescriptionsAndRecords, {
        objectName: '$selectedObject',
        filters: '$filterCriteria',
        customLogic: '$appliedCustomLogic',  // Add this line for dynamic filters
        offset: '$offset',
        recordLimit: '$limit'
    })
    wiredData(result) {
        this.wiredDataResult = result;
        if (result.data || result.error) {
            this.isLoading = false;
        }
        if (result.data) {
            const data = result.data;
            console.log('data ........ ', data);
            this.totalSize = data.totalSize;
            this.fieldOptions = data.fieldDescriptions
                .map(field => ({
                    label: field.label,
                    value: field.value,
                    picklistValues: field.picklistValues
                }))
                .sort((a, b) => a.label.localeCompare(b.label));

            // Append new records to the existing list
            let newRecords = data.records.map(record => ({
                ...record,
                isSelected: this.selectedRecords.includes(record.Id)
            }));

            if (this.offset === 0) {
                this.records = newRecords;
            } else {
                this.records = [...this.records, ...newRecords];
            }

            this.filteredRecords = [...this.records];
            this.applyFilters();
        } else if (result.error) {
            console.error('Error loading data', result.error);
        }
    }

    // Load more records on scroll
    renderedCallback() {
        if (!this._scrollHandlerAttached) {
            const tableContainer = this.template.querySelector('.slds-table_container');
            if (tableContainer) {
                tableContainer.addEventListener('scroll', this.handleTableScroll.bind(this));
                this._scrollHandlerAttached = true;
            }
        }
    }

    // Modify handleCustomFilterLogicChange to only update the value // Add this for dynamic filters
    handleCustomFilterLogicChange(event) {
        this.customFilterLogic = event.target.value;
    }

    handleTableScroll(event) {
        const container = event.target;
        if (container.scrollTop + container.clientHeight >= container.scrollHeight - 100 &&
            this.loadedCount < this.totalSize &&
            !this.isLoadingMore) {
            this.loadMoreRecords();
        }
    }

    async loadMoreRecords() {
        this.isLoadingMore = true;
        this.offset += this.limit;

        // Wait for the data to load
        await new Promise(resolve => setTimeout(resolve, 300));

        // After new records are loaded, update the UI to reflect selected records
        this.records = this.records.map(record => ({
            ...record,
            isSelected: this.selectedRecords.includes(record.Id)
        }));

        this.filteredRecords = this.filteredRecords.map(record => ({
            ...record,
            isSelected: this.selectedRecords.includes(record.Id)
        }));

        this.loadedCount = this.records.length;
        this.isLoadingMore = false;
    }

    resetSelectionState() {
        this.selectAll = false;
        this.selectedRecords = [];
        this.records = this.records.map(record => ({
            ...record,
            isSelected: false
        }));
        this.filteredRecords = this.filteredRecords.map(record => ({
            ...record,
            isSelected: false
        }));
    }

    // Filter panel handlers
    openFilterPanel() {
        this.showFilterPanel = true;
    }

    closeFilterPanel() {
        this.showFilterPanel = false;
    }

    addFilter() {
        this.editingFilter = { field: '', operator: '=', value: '', valueOptions: [] };
        this.editingIndex = this.filterCriteria.length;
        this.showFilterEditModal = true;
        this.appliedCustomLogic = ''; // Add this line for dynamic filters
        this.resetSelectionState(); // Reset selection state when a new filter is added
    }

    editFilter(event) {
        const index = event.target.dataset.index;
        const filter = this.filterCriteria[index];
        this.editingFilter = { ...filter };
        this.editingIndex = index;
        this.showFilterEditModal = true;
    }

    closeEditFilterModal() {
        this.showFilterEditModal = false;
        this.editingFilter = { field: '', operator: '=', value: '', valueOptions: [] };
        this.editingIndex = null;
    }

    handleEditFilterChange(event) {
        const { name, value } = event.target;
        let editingFilter = { ...this.editingFilter, [name]: value };
        if (name === 'field') {
            const selectedField = this.fieldOptions.find(option => option.value === value);
            if (selectedField && selectedField.picklistValues) {
                editingFilter.valueOptions = selectedField.picklistValues.map(item => ({ label: item, value: item }));
            } else {
                editingFilter.valueOptions = undefined;
            }
            editingFilter.value = '';
            editingFilter.fieldLabel = selectedField ? selectedField.label : 'New Filter';
        }
        this.editingFilter = editingFilter;
    }

    saveEditFilter() {
        let filter = { ...this.editingFilter };
        if (!filter.fieldLabel) {
            const selectedField = this.fieldOptions.find(option => option.value === filter.field);
            filter.fieldLabel = selectedField ? selectedField.label : 'New Filter';
        }
        let criteria = [...this.filterCriteria];
        criteria[this.editingIndex] = filter;
        this.filterCriteria = criteria;
        this.appliedCustomLogic = '';  // Add this line for dynamic filters
        this.showFilterEditModal = false;
        this.editingIndex = null;
        this.resetSelectionState(); // Reset selection state when a filter is edited
        this.applyFilters();
    }

    handlePopoverBackgroundClick(event) {
        if (event.target === this.template.querySelector('.filter-popover-anchor')) {
            this.closeEditFilterModal();
        }
    }

    removeAllFilters() {
        this.filterCriteria = [];
        this.appliedCustomLogic = '';  // Add this line for dynamic filters
        this.customFilterLogic = '';     // ✅ ADD: Reset input field
        this.resetSelectionState(); // Reset selection state when all filters are removed
        this.applyFilters();
    }

    removeFilter(event) {
        const index = event.target.dataset.index;
        this.filterCriteria = this.filterCriteria.filter((_, i) => i != index);
        this.appliedCustomLogic = '';  // Add this line for dynamic filters
        this.resetSelectionState(); // Reset selection state when a filter is removed
        this.applyFilters();
    }

    // applyFilters() {
    //     console.log('Applying filters...');
    //     this.filteredRecords = this.filterRecords(this.records);
    //     this.syncSelectedRecords();

    //     // Update selectAll state based on whether all visible records are selected
    //     const visibleIds = this.visibleRecords.map(r => r.Id);
    //     this.selectAll = visibleIds.length > 0 && visibleIds.every(id => this.selectedRecords.includes(id));
    // }


    // 2. ✅ Your applyFilters() - KEEP EXACTLY AS IS:     // Add this for dynamic filters
    applyFilters() {
        console.log('Applying filters...');
        console.log('Filter Criteria:', JSON.stringify(this.filterCriteria));
        //console.log('Custom Logic:', this.customLogic);
        this.filteredRecords = [...this.records];
        this.syncSelectedRecords();

        // Update selectAll state based on whether all visible records are selected
        const visibleIds = this.visibleRecords.map(r => r.Id);
        this.selectAll = visibleIds.length > 0 && visibleIds.every(id => this.selectedRecords.includes(id));
    }

    // Add this for dynamic filters
    get showCustomFilterLogic() {
        return this.filterCriteria.length > 1;
    }

    getNestedValue(obj, path) {
        return path.split('.').reduce((acc, part) => acc && acc[part], obj);
    }

    filterRecords(records) {
        if (this.filterCriteria.length > 0) {
            return records.filter(record => {
                return this.filterCriteria.every(filter => {
                    const fieldValue = this.getNestedValue(record, filter.field);
                    return this.applyFilterCondition(fieldValue, filter);
                });
            });
        }
        return records;
    }

    applyFilterCondition(fieldValue, filter) {
        const filterValues = filter.value.split(',').map(v => v.trim().toUpperCase());
        const fieldValueStr = String(fieldValue).toUpperCase();
        switch (filter.operator) {
            case OPERATORS.EQUALS:
                return filterValues.includes(fieldValueStr);
            case OPERATORS.NOT_EQUAL:
                return !filterValues.includes(fieldValueStr);
            case OPERATORS.LESS_THAN:
                return filterValues.some(val => fieldValueStr < val);
            case OPERATORS.GREATER_THAN:
                return filterValues.some(val => fieldValueStr > val);
            case OPERATORS.LESS_OR_EQUAL:
                return filterValues.some(val => fieldValueStr <= val);
            case OPERATORS.GREATER_OR_EQUAL:
                return filterValues.some(val => fieldValueStr >= val);
            case OPERATORS.CONTAINS:
                return filterValues.some(val => fieldValueStr.includes(val));
            case OPERATORS.NOT_CONTAINS:
                return !filterValues.some(val => fieldValueStr.includes(val));
            case OPERATORS.STARTS_WITH:
                return filterValues.some(val => fieldValueStr.startsWith(val));
            default:
                return true;
        }
    }

    // syncSelectedRecords() {
    //     const filteredIds = this.filteredRecords.map(r => r.Id);
    //     this.selectedRecords = this.selectedRecords.filter(id => filteredIds.includes(id));
    // }
    syncSelectedRecords() {
        if (this.isParentObject) {
            // For Student_Parent_Relationship__c, sync parent IDs
            const visibleParentIds = this.filteredRecords
                .map(r => r.Student_Parent_Guardian__c)
                .filter(id => id !== undefined);
            this.selectedRecords = this.selectedRecords.filter(id => visibleParentIds.includes(id));
        } else {
            // For other objects, sync record IDs as before
            const filteredIds = this.filteredRecords.map(r => r.Id);
            this.selectedRecords = this.selectedRecords.filter(id => filteredIds.includes(id));
        }
    }

    // Toggle select all
    // async toggleSelectAll(event) {
    //     const isChecked = event.target.checked;
    //     const visibleIds = this.visibleRecords.map(r => r.Id);

    //     if (visibleIds.length === 0) {
    //         this.selectAll = false;
    //         return;
    //     }

    //     this.selectAll = isChecked;
    //     if (isChecked) {
    //         this.isLoading = true;
    //         try {
    //             const allIds = await getAllRecordIds({
    //                 objectName: this.selectedObject,
    //                 filters: this.filterCriteria,
    //                 customLogic: this.appliedCustomLogic  // Add this line for dynamic filters
    //             });
    //             this.selectedRecords = [...new Set(allIds)];

    //             // Update the UI to reflect selected records
    //             this.records = this.records.map(record => ({
    //                 ...record,
    //                 isSelected: allIds.includes(record.Id)
    //             }));

    //             this.filteredRecords = this.filteredRecords.map(record => ({
    //                 ...record,
    //                 isSelected: allIds.includes(record.Id)
    //             }));

    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Success',
    //                     message: `All ${this.totalSize} records selected!`,
    //                     variant: 'success'
    //                 })
    //             );
    //         } catch (error) {
    //             console.error('Error fetching all record IDs:', error);
    //         } finally {
    //             this.isLoading = false;
    //             this.logSelectedIds();
    //         }
    //     } else {
    //         // Only remove the visible records from selectedRecords
    //         this.selectedRecords = this.selectedRecords.filter(id => !visibleIds.includes(id));

    //         // Update the UI to reflect unselected records
    //         this.records = this.records.map(record => ({
    //             ...record,
    //             isSelected: this.selectedRecords.includes(record.Id)
    //         }));

    //         this.filteredRecords = this.filteredRecords.map(record => ({
    //             ...record,
    //             isSelected: this.selectedRecords.includes(record.Id)
    //         }));
    //     }
    // }
    async toggleSelectAll(event) {
        const isChecked = event.target.checked;
        const visibleIds = this.visibleRecords.map(r => r.Id);

        if (visibleIds.length === 0) {
            this.selectAll = false;
            return;
        }

        this.selectAll = isChecked;
        if (isChecked) {
            this.isLoading = true;
            try {
                let allIds;
                if (this.isParentObject) {
                    // For Student_Parent_Relationship__c, fetch parent IDs
                    allIds = await getAllRecordIds({
                        objectName: this.selectedObject,
                        filters: this.filterCriteria,
                        customLogic: this.appliedCustomLogic
                    });
                } else {
                    // For other objects, fetch record IDs as before
                    allIds = await getAllRecordIds({
                        objectName: this.selectedObject,
                        filters: this.filterCriteria,
                        customLogic: this.appliedCustomLogic
                    });
                }

                this.selectedRecords = [...new Set(allIds)];

                // Update UI to reflect selected state
                if (this.isParentObject) {
                    // For Student_Parent_Relationship__c, map parent IDs to child records
                    this.records = this.records.map(record => ({
                        ...record,
                        isSelected: allIds.includes(record.Student_Parent_Guardian__c)
                    }));
                    this.filteredRecords = this.filteredRecords.map(record => ({
                        ...record,
                        isSelected: allIds.includes(record.Student_Parent_Guardian__c)
                    }));
                } else {
                    // For other objects, update as before
                    this.records = this.records.map(record => ({
                        ...record,
                        isSelected: allIds.includes(record.Id)
                    }));
                    this.filteredRecords = this.filteredRecords.map(record => ({
                        ...record,
                        isSelected: allIds.includes(record.Id)
                    }));
                }

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `All ${this.totalSize} records selected!`,
                        variant: 'success'
                    })
                );
            } catch (error) {
                console.error('Error fetching all record IDs:', error);
            } finally {
                this.isLoading = false;
                this.logSelectedIds();
            }
        } else {
            // Remove all selected records
            this.selectedRecords = [];
            this.records = this.records.map(record => ({
                ...record,
                isSelected: false
            }));
            this.filteredRecords = this.filteredRecords.map(record => ({
                ...record,
                isSelected: false
            }));
        }
    }

    // Handle checkbox selection
    // handleCheckbox(event) {
    //     const recordId = event.target.dataset.id;
    //     const isChecked = event.target.checked;

    //     this.records = this.records.map(record => {
    //         if (record.Id === recordId) {
    //             return { ...record, isSelected: isChecked };
    //         }
    //         return record;
    //     });

    //     this.filteredRecords = this.filteredRecords.map(record => {
    //         if (record.Id === recordId) {
    //             return { ...record, isSelected: isChecked };
    //         }
    //         return record;
    //     });

    //     if (isChecked) {
    //         if (!this.selectedRecords.includes(recordId)) {
    //             this.selectedRecords = [...this.selectedRecords, recordId];
    //         }
    //     } else {
    //         this.selectedRecords = this.selectedRecords.filter(id => id !== recordId);
    //     }

    //     const visibleIds = this.visibleRecords.map(r => r.Id);
    //     this.selectAll = visibleIds.every(id => this.selectedRecords.includes(id));
    //     this.logSelectedIds();
    // }

    // handleCheckbox(event) {
    //     const recordId = event.target.dataset.id;
    //     const isChecked = event.target.checked;

    //     if (this.isParentObject) {
    //         // For Student_Parent_Relationship__c, use parent ID
    //         const parentId = this.records.find(r => r.Id === recordId)?.Student_Parent_Guardian__c;
    //         if (isChecked) {
    //             if (!this.selectedRecords.includes(parentId)) {
    //                 this.selectedRecords = [...this.selectedRecords, parentId];
    //             }
    //         } else {
    //             this.selectedRecords = this.selectedRecords.filter(id => id !== parentId);
    //         }
    //     } else {
    //         // For other objects, use record ID as before
    //         if (isChecked) {
    //             if (!this.selectedRecords.includes(recordId)) {
    //                 this.selectedRecords = [...this.selectedRecords, recordId];
    //             }
    //         } else {
    //             this.selectedRecords = this.selectedRecords.filter(id => id !== recordId);
    //         }
    //     }

    //     // Update UI
    //     if (this.isParentObject) {
    //         this.records = this.records.map(record => ({
    //             ...record,
    //             isSelected: this.selectedRecords.includes(record.Student_Parent_Guardian__c)
    //         }));
    //         this.filteredRecords = this.filteredRecords.map(record => ({
    //             ...record,
    //             isSelected: this.selectedRecords.includes(record.Student_Parent_Guardian__c)
    //         }));
    //     } else {
    //         this.records = this.records.map(record => ({
    //             ...record,
    //             isSelected: this.selectedRecords.includes(record.Id)
    //         }));
    //         this.filteredRecords = this.filteredRecords.map(record => ({
    //             ...record,
    //             isSelected: this.selectedRecords.includes(record.Id)
    //         }));
    //     }

    //     const visibleIds = this.visibleRecords.map(r => r.Id);
    //     if (this.isParentObject) {
    //         this.selectAll = visibleIds.every(id =>
    //             this.selectedRecords.includes(this.records.find(r => r.Id === id)?.Student_Parent_Guardian__c)
    //         );
    //     } else {
    //         this.selectAll = visibleIds.every(id => this.selectedRecords.includes(id));
    //     }
    //     this.logSelectedIds();
    // }
    handleCheckbox(event) {
        const recordId = event.target.dataset.id;
        const isChecked = event.target.checked;
        console.log('Record ID:', recordId);
        console.log('Parent ID:', this.records.find(r => r.Id === recordId)?.Student_Parent_Guardian__c);

        if (this.isParentObject) {
            // For Student_Parent_Relationship__c, use the parent ID (Student_Parent_Guardian__c)
            const parentId = this.records.find(r => r.Id === recordId)?.Student_Parent_Guardian__c;
            if (isChecked) {
                if (!this.selectedRecords.includes(parentId)) {
                    this.selectedRecords = [...this.selectedRecords, parentId];
                }
            } else {
                this.selectedRecords = this.selectedRecords.filter(id => id !== parentId);
            }
        } else {
            // For other objects, use the record ID
            if (isChecked) {
                if (!this.selectedRecords.includes(recordId)) {
                    this.selectedRecords = [...this.selectedRecords, recordId];
                }
            } else {
                this.selectedRecords = this.selectedRecords.filter(id => id !== recordId);
            }
        }

        // Update UI
        if (this.isParentObject) {
            this.records = this.records.map(record => ({
                ...record,
                isSelected: this.selectedRecords.includes(record.Student_Parent_Guardian__c)
            }));
            this.filteredRecords = this.filteredRecords.map(record => ({
                ...record,
                isSelected: this.selectedRecords.includes(record.Student_Parent_Guardian__c)
            }));
        } else {
            this.records = this.records.map(record => ({
                ...record,
                isSelected: this.selectedRecords.includes(record.Id)
            }));
            this.filteredRecords = this.filteredRecords.map(record => ({
                ...record,
                isSelected: this.selectedRecords.includes(record.Id)
            }));
        }

        const visibleIds = this.visibleRecords.map(r => r.Id);
        if (this.isParentObject) {
            this.selectAll = visibleIds.every(id =>
                this.selectedRecords.includes(this.records.find(r => r.Id === id)?.Student_Parent_Guardian__c)
            );
        } else {
            this.selectAll = visibleIds.every(id => this.selectedRecords.includes(id));
        }
        this.logSelectedIds();
    }

    // Navigation handlers
    handleSchoolNameClick(event) {
        if (!this.isIOSObject) return;
        const recordId = event.currentTarget.dataset.recordId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'School_App__c',
                actionName: 'view'
            }
        });
    }

    handleAccountClick(event) {
        const accountId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    handleStudentClick(event) {
        const studentId = event.currentTarget.dataset.recordId;
        console.log('Navigating to Student record with ID:', studentId); // Debug log
        if (studentId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: studentId,
                    objectApiName: 'Student__c',
                    actionName: 'view'
                }
            });
        } else {
            console.error('Student ID is undefined!');
        }
    }

    // Modify saveCustomFilterLogic to apply the custom logic   // Add this for dynamic filters
    saveCustomFilterLogic() {
        console.log('saveCustomFilterLogic called');
        if (!this.customFilterLogic) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter custom filter logic!',
                    variant: 'error'
                })
            );
            return;
        }

        // Set the applied custom logic to trigger the wire method
        this.appliedCustomLogic = this.customFilterLogic;

        // Reset the wire adapter to refresh data with the new custom logic
        this.wiredDataResult = null;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Custom filter logic applied!',
                variant: 'success'
            })
        );
    }

    // // iOS/Android Notification Modal Handlers
    // openNotificationModal() {
    //     if (this.isIOSObject) {
    //         console.log('Opening iOS/Android Notification Modal');
    //         this.showIOSNotificationModal = true;
    //     } else if (this.isContactObject) {
    //         console.log('Opening Contact Notification Modal');
    //         this.showContactNotificationModal = true;
    //     }
    //     this.logSelectedIds();
    // }

    // Open correct modal based on object
    openNotificationModal() {
        if (this.isIOSObject) {
            this.showIOSNotificationModal = true;
        } else if (this.isContactObject) {
            this.showContactNotificationModal = true;
        } else if (this.isStudentObject) {
            this.showStudentNotificationModal = true;
        } else if (this.isParentObject) {
            this.showParentNotificationModal = true;
        }
        this.logSelectedIds();
    }
    closeIOSNotificationModal() {
        this.showIOSNotificationModal = false;
        this.isIOSModalLoading = false;
        this.iosNotificationTitle = '';
        this.iosNotificationBody = '';
        this.iosNotificationImageUrl = '';
        this.iosNotificationLaunchUrl = '';
        this.iosScheduledDate = '';
        this.iosScheduledTime = '';
        this.iosIsPinChecked = false;
        this.iosPinEndDate = '';

        // Reset poll data when closing the modal
        this.storedPollData = null;
        this.pollButtonLabel = 'Add Poll';
        this.pollQuestionId = null;
    }

    handleIOSTitleChange(event) {
        this.iosNotificationTitle = event.target.value;
    }

    handleIOSBodyChange(event) {
        this.iosNotificationBody = event.target.value;
    }

    handleIOSImageUrlChange(event) {
        this.iosNotificationImageUrl = event.target.value;
    }

    handleIOSLaunchUrlChange(event) {
        this.iosNotificationLaunchUrl = event.target.value;
    }

    handleIOSScheduledDateChange(event) {
        this.iosScheduledDate = event.target.value;
    }

    handleIOSScheduledTimeChange(event) {
        this.iosScheduledTime = event.target.value;
    }

    handleIOSPinCheckboxChange(event) {
        this.iosIsPinChecked = event.target.checked;
    }

    // Add this method to handle changes to the pin end date
    handleIOSPinEndDateChange(event) {
        this.iosPinEndDate = event.target.value;
        console.log('Pin End Date selected:', this.iosPinEndDate);
    }

    closeContactNotificationModal() {
        this.showContactNotificationModal = false;
        this.isContactModalLoading = false;
        this.contactNotificationTitle = '';
        this.contactNotificationBody = '';
        this.contactNotificationImageUrl = '';
        this.contactNotificationLaunchUrl = '';
    }


    handleContactTitleChange(event) {
        this.contactNotificationTitle = event.target.value;
    }

    handleContactBodyChange(event) {
        this.contactNotificationBody = event.target.value;
    }

    handleContactImageUrlChange(event) {
        this.contactNotificationImageUrl = event.target.value;
    }

    handleContactLaunchUrlChange(event) {
        this.contactNotificationLaunchUrl = event.target.value;
    }

    handleStudentTitleChange(event) {
        this.studentNotificationTitle = event.target.value;
    }

    handleStudentBodyChange(event) {
        this.studentNotificationBody = event.target.value;
    }

    handleStudentImageUrlChange(event) {
        this.studentNotificationImageUrl = event.target.value;
    }

    // Student Modal Handlers
    closeStudentNotificationModal() {
        this.showStudentNotificationModal = false;
        this.isStudentModalLoading = false;
        this.studentNotificationTitle = '';
        this.studentNotificationBody = '';
        this.studentNotificationImageUrl = '';
    }

    // Parent Modal Handlers
    closeParentNotificationModal() {
        this.showParentNotificationModal = false;
        this.isParentModalLoading = false;
        this.parentNotificationTitle = '';
        this.parentNotificationBody = '';
        this.parentNotificationImageUrl = '';
    }

    handleParentTitleChange(event) {
        this.parentNotificationTitle = event.target.value;
    }

    handleParentBodyChange(event) {
        this.parentNotificationBody = event.target.value;
    }

    handleParentImageUrlChange(event) {
        this.parentNotificationImageUrl = event.target.value;
    }
    openIOSPollModal() {
        this.showIOSPollModal = true;

        // Pre-fill the poll modal if stored data exists
        if (this.storedPollData) {
            this.pollQuestion = this.storedPollData.question;
            this.pollOptions = this.storedPollData.options.map((option, index) => ({
                id: `option-${index + 1}`,
                value: option,
                placeholder: `Enter option ${index + 1}`,
                isRequired: true,
                canDelete: index >= 2
            }));
            this.pollEndDate = this.storedPollData.endDate;
            this.pollEndTime = this.storedPollData.endTime;
        } else {
            // Reset to default if no stored data
            this.pollQuestion = '';
            this.pollOptions = [
                { id: 'option-1', value: '', placeholder: 'Enter option 1', isRequired: true },
                { id: 'option-2', value: '', placeholder: 'Enter option 2', isRequired: true }
            ];
            this.pollEndDate = '';
            this.pollEndTime = '';
        }
    }

    closeIOSPollModal() {
        this.showIOSPollModal = false;
        this.pollQuestion = '';
        this.pollOptions = [
            { id: 'option-1', value: '', placeholder: 'Enter option 1' },
            { id: 'option-2', value: '', placeholder: 'Enter option 2' }
        ];
        this.nextPollOptionId = 3;
        this.pollEndDate = '';
        this.pollEndTime = '';
    }

    handlePollQuestionChange(event) {
        this.pollQuestion = event.target.value;
    }

    handlePollOptionChange(event) {
        const index = parseInt(event.target.dataset.index);
        const newOptions = [...this.pollOptions];
        newOptions[index].value = event.target.value;
        this.pollOptions = newOptions;
    }

    addPollOption() {
        if (this.pollOptions.length < 5) {
            const newOption = {
                id: `option-${this.nextPollOptionId}`,
                value: '',
                placeholder: `Enter option ${this.nextPollOptionId}`,
                isRequired: false,
                canDelete: true
            };
            this.pollOptions = [...this.pollOptions, newOption];
            this.nextPollOptionId++;
        }
    }

    removePollOption(event) {
        const index = parseInt(event.target.dataset.index);
        if (this.pollOptions.length > 2) {
            this.pollOptions = this.pollOptions.filter((_, i) => i !== index);
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'At least 2 options are required!',
                    variant: 'error'
                })
            );
        }
    }

    handlePollEndDateChange(event) {
        this.pollEndDate = event.target.value;
    }

    handlePollEndTimeChange(event) {
        this.pollEndTime = event.target.value;
    }

    // Save Poll (API call)
    savePoll() {
        const options = this.pollOptions
            .map((opt, index) => ({
                Poll_Option: opt.value,
                Sort_Order: index,
                Active_Status: "true"
            }))
            .filter(opt => opt.Poll_Option.trim() !== '');

        if (options.length < 2) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please provide at least 2 poll options!',
                    variant: 'error'
                })
            );
            return;
        }

        const pollData = {
            Account_Id: "0014W00002aAD6wQAG",
            Poll_Question: this.pollQuestion,
            Poll_Start_Date: new Date().toISOString().split('T')[0],
            Poll_Start_Time: new Date().toISOString().split('T')[1].split('.')[0],
            Poll_End_Date: this.pollEndDate,
            Poll_End_Time: this.pollEndTime,
            Active_Status: "true",
            Poll_Options: options
        };

        this.isIOSModalLoading = true;

        fetch('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/poll', {
            method: 'POST',
            headers: {
                'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6InRlYWNoZXIuc29sdmVkQHN5c3RlbS51c2VyIiwicm9sZSI6InRlYWNoZXIiLCJpZCI6IjAwM052MDAwMDBKQXk4MUlBRCIsImlhdCI6MTczMzQwNjAyNn0.Hnkzas3BJpT2bjeUAtMSNJxgaIdxBlebp29YlmgOoFU',
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(pollData)
        })
            .then(response => {
                if (!response.ok) {
                    throw new Error(`Failed to save poll: ${response.status} ${response.statusText}`);
                }
                return response.json();
            })
            .then(data => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: '🎉 Success!',
                        message: 'Poll saved successfully!',
                        variant: 'success'
                    })
                );
                this.pollQuestionId = data.body.Poll_Question.Id;

                // Store the poll data for editing
                this.storedPollData = {
                    question: this.pollQuestion,
                    options: this.pollOptions.map(opt => opt.value),
                    endDate: this.pollEndDate,
                    endTime: this.pollEndTime
                };

                this.pollButtonLabel = 'Edit Poll';
                this.closeIOSPollModal();
            })
            .catch(error => {
                console.error('Error saving poll:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isIOSModalLoading = false;
            });
    }

    // Send iOS/Android Notification
    // sendIOSNotification() {
    //     if (!this.iosNotificationTitle || !this.iosNotificationBody) {
    //         this.dispatchEvent(
    //             new ShowToastEvent({
    //                 title: 'Error',
    //                 message: 'Title and Message are required!',
    //                 variant: 'error'
    //             })
    //         );
    //         return;
    //     }
    //     // First confirmation
    //     const firstConfirm = confirm('Are you sure you want to send this Push Notification to all the selected Schools?');
    //     if (!firstConfirm) return;

    //     // Second confirmation
    //     const secondConfirm = confirm('You cannot undo this action. Continue?');
    //     if (!secondConfirm) return;

    //     const requestBody = {
    //         ids: this.selectedRecords,
    //         title: this.iosNotificationTitle,
    //         message: this.iosNotificationBody,
    //         imageUrl: this.iosNotificationImageUrl,
    //         url: this.iosNotificationLaunchUrl,
    //         scheduleDate: this.iosScheduledDate,
    //         scheduleTime: this.iosScheduledTime,
    //         pinned: this.iosIsPinChecked,
    //         pollQuestionId: this.pollQuestionId,
    //         pinEndDate: this.iosPinEndDate,
    //     };

    //     console.log('Request Body for iOS Notification:', JSON.stringify(requestBody));

    //     this.isIOSModalLoading = true;
    //     this.isLoading = true;

    //     fetch('https://9nwyf9euuf.execute-api.us-east-2.amazonaws.com/prod/send-mass-push-notifications', {
    //         method: 'POST',
    //         headers: {
    //             'Authorization': 'r?ftDEZ_qdt=VjD#W@S2LM8FZT97Nx',
    //             'Content-Type': 'application/json',
    //         },
    //         body: JSON.stringify(requestBody),
    //     })
    //         .then(async response => {
    //             this.isLoading = false;
    //             const data = await response.json();
    //             console.log('Response Data :', data);
    //             if (response.ok) {
    //                 this.dispatchEvent(
    //                     new ShowToastEvent({
    //                         title: '🎉 Success!',
    //                         message: `Notification sent to ${this.selectedRecords.length} schools!`,
    //                         variant: 'success'
    //                     })
    //                 );

    //                 //    if (response.ok) {
    //                 // this.successRecordCount = this.selectedRecords.length;
    //                 // this.showSuccessModal = true;

    //                 // Reset poll data after sending the push message
    //                 this.storedPollData = null;
    //                 this.pollButtonLabel = 'Add Poll';
    //                 this.pollQuestionId = null;

    //                 this.closeIOSNotificationModal();
    //                 // Refresh the page after success
    //                 // window.location.reload();
    //             } else {
    //                 this.isIOSModalLoading = false;
    //                 throw new Error(`Failed: ${response.status} ${response.statusText}`);
    //             }
    //         })
    //         .catch(error => {
    //             this.isLoading = false;
    //             this.isIOSModalLoading = false;
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Error',
    //                     message: error.message,
    //                     variant: 'error'
    //                 })
    //             );
    //         });
    // }
    sendIOSNotification() {
        if (!this.iosNotificationTitle || !this.iosNotificationBody) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Title and Message are required!',
                    variant: 'error'
                })
            );
            return;
        }

        // First confirmation
        const firstConfirm = confirm('Are you sure you want to send this Push Notification to all the selected Schools?');
        if (!firstConfirm) return;

        // Second confirmation
        const secondConfirm = confirm('You cannot undo this action. Continue?');
        if (!secondConfirm) return;

        // Append the invisible emoji to title and message
        const titleWithEmoji = this.iosNotificationTitle + 'ㅤ';
        const messageWithEmoji = this.iosNotificationBody + 'ㅤ';

        const requestBody = {
            ids: this.selectedRecords,
            title: titleWithEmoji,
            message: messageWithEmoji,
            imageUrl: this.iosNotificationImageUrl,
            url: this.iosNotificationLaunchUrl,
            scheduleDate: this.iosScheduledDate,
            scheduleTime: this.iosScheduledTime,
            pinned: this.iosIsPinChecked,
            pollQuestionId: this.pollQuestionId,
            pinEndDate: this.iosPinEndDate,
        };

        console.log('Request Body for iOS Notification:', JSON.stringify(requestBody));

        this.isIOSModalLoading = true;
        this.isLoading = true;

        fetch('https://9nwyf9euuf.execute-api.us-east-2.amazonaws.com/prod/send-mass-push-notifications', {
            method: 'POST',
            headers: {
                'Authorization': 'r?ftDEZ_qdt=VjD#W@S2LM8FZT97Nx',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody),
        })
            .then(async response => {
                this.isLoading = false;
                const data = await response.json();
                console.log('Response Data :', data);
                if (response.ok) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: '🎉 Success!',
                            message: `Notification sent to ${this.selectedRecords.length} schools!`,
                            variant: 'success'
                        })
                    );

                    // Reset poll data after sending the push message
                    this.storedPollData = null;
                    this.pollButtonLabel = 'Add Poll';
                    this.pollQuestionId = null;

                    this.closeIOSNotificationModal();
                } else {
                    this.isIOSModalLoading = false;
                    throw new Error(`Failed: ${response.status} ${response.statusText}`);
                }
            })
            .catch(error => {
                this.isLoading = false;
                this.isIOSModalLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.message,
                        variant: 'error'
                    })
                );
            });
    }

    // Send Contact Notification
    sendContactNotification() {
        if (!this.contactNotificationTitle || !this.contactNotificationBody) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Title and Message are required!',
                    variant: 'error'
                })
            );
            return;
        }

        // First confirmation
        const firstConfirm = confirm('Are you sure you want to send this Push Notification to all the selected Schools?');
        if (!firstConfirm) return;

        // Second confirmation
        const secondConfirm = confirm('You cannot undo this action. Continue?');
        if (!secondConfirm) return;

        const attachments = this.contactNotificationImageUrl ? [{
            sort_order: 0,
            url: this.contactNotificationImageUrl
        }] : [];

        const requestBody = {
            IsStaff_Story: true,
            title: this.contactNotificationTitle,
            message: this.contactNotificationBody,
            attachments: attachments,
            launch_url: this.contactNotificationLaunchUrl,
            Story_Recepients: this.selectedRecords.map(id => ({
                Teacher_Id: id
            }))
        };

        console.log('Request Body for Contacts:', JSON.stringify(requestBody));

        this.isContactModalLoading = true;
        this.isLoading = true;

        fetch('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-and-social-feed/staff-story', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestBody)
        })
            .then(async response => {
                this.isLoading = false;
                const data = await response.json();
                console.log('Response Data:', data);
                if (response.ok && (!data.statusCode || data.statusCode === 200)) {
                    // Only show success if the response body does NOT contain an error
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: '🎉 Success!',
                            message: `Notification sent to ${this.selectedRecords.length} staff members!`,
                            variant: 'success'
                        })
                    );
                    this.closeContactNotificationModal();
                } else {
                    // Show error if the response body contains an error
                    throw new Error(data.message || `Failed: ${response.status} ${response.statusText}`);
                }
            })
            .catch(error => {
                this.isLoading = false;
                this.isContactModalLoading = false;
                console.error('Error:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.message,
                        variant: 'error'
                    })
                );
            });
    }

    sendStudentNotification() {
        if (!this.studentNotificationTitle || !this.studentNotificationBody) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Title and Message are required!',
                variant: 'error'
            }));
            return;
        }

        const firstConfirm = confirm('Are you sure you want to send this Push Notification to all selected STUDENTS?');
        if (!firstConfirm) return;

        const secondConfirm = confirm('You cannot undo this action. Continue?');
        if (!secondConfirm) return;

        // Build recipients array in required format
        const storyRecipients = this.selectedRecords.map(id => ({
            Student_Id: id
        }));

        const attachments = this.studentNotificationImageUrl ? [{
            sort_order: 0,
            url: this.studentNotificationImageUrl
        }] : [];

        const requestBody = {
            IsStudent_Story: true,
            title: this.studentNotificationTitle,
            message: this.studentNotificationBody,
            attachments: attachments,
            launch_url: "",
            Story_Recepients: storyRecipients
        };

        this.isStudentModalLoading = true;
        this.isLoading = true;

        fetch('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-and-social-feed/student-story', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody),
        })
            .then(async response => {
                this.isLoading = false;
                const data = await response.json();

                if (response.ok) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: '🎉 Success!',
                        message: `Notification sent to ${this.selectedRecords.length} students!`,
                        variant: 'success'
                    }));
                    this.closeStudentNotificationModal();
                } else {
                    this.isStudentModalLoading = false;
                    throw new Error(`Failed: ${response.status} ${response.statusText}`);
                }
            })
            .catch(error => {
                this.isLoading = false;
                this.isStudentModalLoading = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.message,
                    variant: 'error'
                }));
            });
    }

    // sendParentNotification() {
    //     if (!this.parentNotificationTitle || !this.parentNotificationBody) {
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: 'Error',
    //             message: 'Title and Message are required!',
    //             variant: 'error'
    //         }));
    //         return;
    //     }

    //     const firstConfirm = confirm('Are you sure you want to send this Push Notification to all selected PARENTS?');
    //     if (!firstConfirm) return;

    //     const secondConfirm = confirm('You cannot undo this action. Continue?');
    //     if (!secondConfirm) return;

    //     this.isParentModalLoading = true;
    //     this.isLoading = true;

    //     getAllRecordIds({
    //         objectName: 'Student_Parent_Relationship__c',
    //         filters: this.filterCriteria,
    //         customLogic: this.appliedCustomLogic
    //     })
    //         .then(parentIds => {

    //             // Build recipients array in required format
    //             const storyRecipients = parentIds.map(id => ({
    //                 Parent_Id: id
    //             }));

    //             const requestBody = {
    //                 IsParent_Story: true,
    //                 title: this.parentNotificationTitle,
    //                 message: this.parentNotificationBody,
    //                 attachments: [],
    //                 launch_url: "",
    //                 Story_Recepients: storyRecipients
    //             };
    //             console.log('Request Body for Parent Notification:', JSON.stringify(requestBody));
    //             return fetch('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-and-social-feed/parent-story', {
    //                 method: 'POST',
    //                 headers: {
    //                     'Authorization': 'r?ftDEZ_qdt=VjD#W@S2LM8FZT97Nx',
    //                     'Content-Type': 'application/json',
    //                 },
    //                 body: JSON.stringify(requestBody),
    //             });
    //         })
    //         .then(async response => {
    //             this.isLoading = false;
    //             const data = await response.json();

    //             if (response.ok) {
    //                 this.dispatchEvent(new ShowToastEvent({
    //                     title: '🎉 Success!',
    //                     message: `Notification sent to parents!`,
    //                     variant: 'success'
    //                 }));
    //                 this.closeParentNotificationModal();
    //             } else {
    //                 this.isParentModalLoading = false;
    //                 throw new Error(`Failed: ${response.status} ${response.statusText}`);
    //             }
    //         })
    //         .catch(error => {
    //             this.isLoading = false;
    //             this.isParentModalLoading = false;
    //             this.dispatchEvent(new ShowToastEvent({
    //                 title: 'Error',
    //                 message: error.message,
    //                 variant: 'error'
    //             }));
    //         });
    // }

    // sendParentNotification() {
    //     if (!this.parentNotificationTitle || !this.parentNotificationBody) {
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: 'Error',
    //             message: 'Title and Message are required!',
    //             variant: 'error'
    //         }));
    //         return;
    //     }

    //     const firstConfirm = confirm('Are you sure you want to send this Push Notification to the selected PARENTS?');
    //     if (!firstConfirm) return;

    //     const secondConfirm = confirm('You cannot undo this action. Continue?');
    //     if (!secondConfirm) return;

    //     this.isParentModalLoading = true;
    //     this.isLoading = true;

    //     // Use the already selected parent IDs
    //     const storyRecipients = this.selectedRecords.map(id => ({
    //         Parent_Id: id
    //     }));

    //     const requestBody = {
    //         IsParent_Story: true,
    //         title: this.parentNotificationTitle,
    //         message: this.parentNotificationBody,
    //         attachments: [],
    //         launch_url: "",
    //         Story_Recepients: storyRecipients
    //     };

    //     fetch('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-and-social-feed/parent-story', {
    //         method: 'POST',
    //         headers: {
    //             'Authorization': 'r?ftDEZ_qdt=VjD#W@S2LM8FZT97Nx',
    //             'Content-Type': 'application/json',
    //         },
    //         body: JSON.stringify(requestBody),
    //     })
    //         .then(response => response.json())
    //         .then(data => {
    //             this.isLoading = false;
    //             this.isParentModalLoading = false;
    //             this.dispatchEvent(new ShowToastEvent({
    //                 title: '🎉 Success!',
    //                 message: `Notification sent to ${this.selectedRecords.length} parents!`,
    //                 variant: 'success'
    //             }));
    //             this.closeParentNotificationModal();
    //         })
    //         .catch(error => {
    //             this.isLoading = false;
    //             this.isParentModalLoading = false;
    //             this.dispatchEvent(new ShowToastEvent({
    //                 title: 'Error',
    //                 message: error.message,
    //                 variant: 'error'
    //             }));
    //         });
    // }


    // last working 
    sendParentNotification() {
        if (!this.parentNotificationTitle || !this.parentNotificationBody) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'Title and Message are required!',
                variant: 'error'
            }));
            return;
        }

        const firstConfirm = confirm('Are you sure you want to send this Push Notification to the selected PARENTS?');
        if (!firstConfirm) return;

        const secondConfirm = confirm('You cannot undo this action. Continue?');
        if (!secondConfirm) return;

        this.isParentModalLoading = true;
        this.isLoading = true;

        // Use the already selected parent IDs
        const storyRecipients = this.selectedRecords.map(id => ({
            Parent_Id: id // This is the parent ID, not the junction object ID
        }));

        const attachments = this.parentNotificationImageUrl ? [{
            sort_order: 0,
            url: this.parentNotificationImageUrl
        }] : [];

        const requestBody = {
            IsParent_Story: true,
            title: this.parentNotificationTitle,
            message: this.parentNotificationBody,
            attachments: attachments,
            launch_url: "",
            Story_Recepients: storyRecipients
        };

        console.log('Request Body for Parent Notification:', JSON.stringify(requestBody));

        fetch('https://anl2h22jc4.execute-api.us-east-2.amazonaws.com/production/news-and-social-feed/parent-story', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody),
        })
            .then(response => response.json())
            .then(data => {
                this.isLoading = false;
                this.isParentModalLoading = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: '🎉 Success!',
                    message: `Notification sent to ${this.selectedRecords.length} parents!`,
                    variant: 'success'
                }));
                this.closeParentNotificationModal();
            })
            .catch(error => {
                this.isLoading = false;
                this.isParentModalLoading = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.message,
                    variant: 'error'
                }));
            });
    }

}