import { LightningElement, wire, api, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { classSet } from 'lightning/utils';
import getContactRecords from '@salesforce/apex/GradedPlusStandalone.showRecords';

export default class GradedPlusStandalone extends LightningElement {

        @track disableNextButton = false;
        @track showSpinner = false;

        @api recordId;
        data = [];
        columns = [];
        displayedColumns = [];
        selectedColumns = [];
        columnOptions = [];

        currentPage = 1;
        limits = 5;

        loading = false;
        isFirstPage = true;
        isLastPage = false;
        serialNumber = 1;
        showSpinner = false;
        isFullScreen = false;
        isTableVisible = true;
        disableNextButton = false;
        // Add a property to store the current offset before switching to full-screen mode
        storedOffset = 0;

        get fullScreenClass() {
                return this.isFullScreen ? 'full-screen' : '';
        }
        get buttonLabel() {
                return this.isFullScreen ? 'Close' : 'View All';
        }
        get containerClass() {
                return classSet({
                        container: true,
                        'full-screen': this.isFullScreen,
                });
        }


        toggleFullScreen() {
                this.isFullScreen = !this.isFullScreen;
                if (this.isFullScreen) {
                        // document.body.classList.add('hide-scroll'); 
                        //this.template.querySelector('lightning-card').classList.add('full-screen');
                        this.showSpinner = true;
                        this.isTableVisible = false;
                        console.log('this.currentPage:::::', this.currentPage);
                        // Store the current offset before switching to full-screen mode
                        this.storedOffset = (this.currentPage - 1) * this.limits;
                        this.limits = 100;
                        this.template.querySelector('.pagination-controls').classList.add('sticky')
                        // Add the style to the body to hide vertical scrollbar
                        document.body.classList.add('desktop', 'slds-wcag');
                        document.body.style.overflowY = 'hidden';
                        this.fetchData().finally(() => {
                                this.showSpinner = false;
                                this.isTableVisible = true;
                        });
                } else {
                        // document.body.classList.remove('hide-scroll'); 
                        // this.template.querySelector('lightning-card').classList.remove('full-screen');
                        this.showSpinner = true;
                        this.isTableVisible = true;
                        this.isFullScreen = false;
                        this.limits = 5;
                        this.template.querySelector('.pagination-controls').classList.remove('sticky');
                        // Use the stored offset when switching back to normal view
                        this.currentPage = Math.ceil((this.storedOffset + 1) / this.limits);
                        // Remove the style from the body to show vertical scrollbar
                        document.body.classList.remove('desktop', 'slds-wcag');
                        document.body.style.cssText += 'overflow-y: auto !important;';
                        document.body.classList.remove('full-screen'); // Remove the full-screen class                      
                        this.fetchData().finally(() => {
                                this.showSpinner = false;
                                this.isTableVisible = true;
                                this.limits = 5;
                        });
                }
                // this.showSpinner = true;
                // this.fetchData().finally(() => {
                //     this.showSpinner = false;
                // });
        }

        connectedCallback() {

                this.getAllContact();
                // Add an event listener for the popstate event
                window.addEventListener('popstate', () => {
                        this.toggleFullScreen();
                });
        }

        renderedCallback() {
                // Add an event listener for the popstate event
                window.addEventListener('popstate', () => {
                        this.toggleFullScreen();
                });
        }

        getAllContact() {
                getContactRecords({ recordId: this.recordId, offset: 0, limits: this.limits })
                        .then((result) => {
                                if (result) {
                                        this.data = result.map((row, index) => ({
                                                ...row,
                                                serialNumber: index + 1
                                        }));
                                        if (this.data.length > 0) {
                                                const allKeys = this.data.reduce((keys, row) => {
                                                        Object.keys(row).forEach(key => keys.add(key));
                                                        return keys;
                                                }, new Set());

                                                this.columns = Array.from(allKeys).map((column) => ({
                                                        label: column.replace(/_/g, ' ').replace(/c$/, ''), // Replace underscores with spaces and remove '__c' suffix
                                                        fieldName: column,
                                                        type: column === 'Video_URL__c' ? 'url' : 'text',
                                                        typeAttributes: column === 'Video_URL__c' ? { label: 'View', target: '_blank' } : undefined,
                                                }));

                                                this.columnOptions = this.columns.map((column) => ({
                                                        label: column.label,
                                                        value: column.fieldName
                                                }));
                                                // Remove "Id" pgAdmin 4...
                                                this.columns = this.columns.filter(column => column.fieldName !== 'id');
                                                //    this.columns.reverse();

                                                // Modify the data to update the link in the "Image" column
                                                this.data.forEach((row) => {
                                                        if (row.last_event_time) {
                                                                const dateObj = new Date(row.last_event_time);
                                                                const year = dateObj.getFullYear();
                                                                const month = String(dateObj.getMonth() + 1).padStart(2, '0');
                                                                const day = String(dateObj.getDate()).padStart(2, '0');
                                                                row.last_event_time = `${year}/${month}/${day}`;
                                                        }
                                                });

                                                // Modify the displayedColumns array to include the new column
                                                this.displayedColumns = [
                                                        { label: 'S.No', fieldName: 'serialNumber', type: 'number', cellAttributes: { alignment: 'center' } },
                                                        ...this.columns.filter(column => column.fieldName !== 'serialNumber')
                                                ];

                                        } else {
                                                // Disable pagination buttons when there's no data
                                                if (this.data.length === 0) {
                                                        console.log('Inide the else to disable next button:::::', this.data);
                                                        this.disableNextButton = true;
                                                        this.disableViewAll = true;
                                                        this.isFirstPage = true;
                                                }
                                        }
                                } else {
                                        console.error('Error retrieving contact records:', error);
                                }
                        })
                        .catch((error) => {
                                console.log('Error: ', error);
                        });
        }

        // ...
        handleFirstPage() {
                this.currentPage = 1;
                this.fetchData();
        }

        handlePreviousPage() {
                if (!this.isFirstPage) {
                        this.currentPage--;
                        if (this.storedOffset < 100) {
                                this.storedOffset = 0;
                                this.isFirstPage = true;
                        } else {
                                this.storedOffset = this.storedOffset - 100;
                        }
                        this.showSpinner = true;
                        this.fetchData();
                        if (this.currentPage === 1) {
                                this.isFirstPage = true;
                        }
                }
        }

        handleNextPage() {
                console.log('inside next button', this.data);
                if (!this.disableNextButton) {
                        console.log('currentPage:::::', this.currentPage);
                        this.currentPage++;
                        this.storedOffset = this.storedOffset + 100;
                        this.showSpinner = true;
                        this.fetchData();
                        this.isFirstPage = false;
                }
        }

        handleLastPage() {
                const totalPages = Math.ceil(this.data.length / this.limits);
                this.currentPage = totalPages;
                this.fetchData();
        }


        fetchData() {
                // const offset = (this.currentPage - 1) * this.limits;
                // Use the stored offset when fetching data
                const offset = this.isFullScreen ? this.storedOffset : (this.currentPage - 1) * this.limits;
                console.log('offset::::::', offset);
                console.log('limits::::::', this.limits);
                console.log('storedOffset::::::', this.storedOffset);
                console.log('isFullScreen::::::', this.isFullScreen);
                if (offset < 5) {
                        this.isFirstPage = true;
                } else {
                        this.isFirstPage = false;
                }

                getContactRecords({ recordId: this.recordId, offset: offset, limits: this.limits })
                        .then((result) => {
                                const startIndex = offset + 1;
                                this.data = result.map((row, index) => ({
                                        ...row,
                                        serialNumber: startIndex + index,

                                }));

                                this.data.forEach((row) => {
                                        if (row.last_event_time) {
                                                const dateObj = new Date(row.last_event_time);
                                                const year = dateObj.getFullYear();
                                                const month = String(dateObj.getMonth() + 1).padStart(2, '0');
                                                const day = String(dateObj.getDate()).padStart(2, '0');
                                                row.last_event_time = `${year}/${month}/${day}`;
                                        }
                                });


                                console.log('result:::::::', result);
                                this.loading = false;
                                this.isLastPage = result.length < this.limits;
                                this.showSpinner = false; // Set showSpinner to false
                                this.isTableVisible = true; // Set isTableVisible to true after fetching the data successfully
                                if (result.length < 5 && this.isFullScreen === false) {
                                        console.log('No more data:::::');
                                        this.disableNextButton = true;
                                        this.disableViewAll = true;
                                        
                                } else if (result.length < 100 && this.isFullScreen === true) {
                                        console.log('No more data::::: fullscreen');
                                        this.disableNextButton = true;
                                        this.isLastPage = true;
                                } else {
                                        this.disableNextButton = false;
                                        this.disableViewAll = false;
                                }
                        })
                        .catch((error) => {
                                console.error('Error retrieving contact records:', error);
                                this.loading = false;
                                this.showToast('Error', 'Error retrieving contact records', 'error');
                                this.showSpinner = false; // Set showSpinner to false
                                this.isTableVisible = true; // Set isTableVisible to true after fetching the data successfully
                        });
        }
}