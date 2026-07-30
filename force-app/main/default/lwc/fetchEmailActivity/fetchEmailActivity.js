import { LightningElement, wire, api , track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { classSet } from 'lightning/utils';
import getContactRecords from '@salesforce/apex/marketing_correspondence.getContactRecords';


export default class FetchEmailActivity extends LightningElement {

    @track disableNextButton = false;
    @track showSpinner = false;

@api recordId;
data = [];
columns = [];
displayedColumns = [];
selectedColumns = [];
columnOptions = [];

currentPage = 1;
recLimit = 10;

loading = false;
isFirstPage = true; 
isLastPage = false;
serialNumber = 1;
showSpinner = false;
isFullScreen = false;
isTableVisible = true;

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
        this.recLimit = 100;
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
        this.recLimit = 10; 
        this.template.querySelector('.pagination-controls').classList.remove('sticky')
   // Remove the style from the body to show vertical scrollbar
            document.body.classList.remove('desktop', 'slds-wcag');
            document.body.style.cssText += 'overflow-y: auto !important;';
            document.body.classList.remove('full-screen'); // Remove the full-screen class 
            this.fetchData().finally(() => {
                this.showSpinner = false;
                this.isTableVisible = true;
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
    getContactRecords({ getUrl: this.recordId, offset: 0, recLimit: this.recLimit })
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
                        label: column.replace(/_/g, ' '), // Replace underscores with spaces,
                        fieldName: column,
                        type: 'text'
                    }));

                    this.columnOptions = this.columns.map((column) => ({
                        label: column.label,
                        value: column.fieldName
                    }));
                    console.log("columns",this.columns)
                   // Remove "Id" pgAdmin 4...
                   this.columns = this.columns.filter(column => column.fieldName !== 'id'  );
                //    this.columns.reverse();

                   this.data.forEach((row) => {
                    if (row.last_event_time) {
                        const dateObj = new Date(row.last_event_time);
                        const year = dateObj.getFullYear();
                        const month = String(dateObj.getMonth() + 1).padStart(2, '0');
                        const day = String(dateObj.getDate()).padStart(2, '0');
                        row.last_event_time = `${year}/${month}/${day}`;
                    }
                });
                
                      // Add "min./Sec" to the label of the Duration column
                      this.displayedColumns = [
                        { label: 'Serial Number', fieldName: 'serialNumber', type: 'number', cellAttributes: { alignment: 'center' } },
                        ...this.columns.filter(column => column.fieldName !== 'serialNumber')
                      //  { label: 'Duration In Minutes', fieldName: 'Duration_minutes__c', type: 'text' }
                    ];
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
            this.showSpinner = true;
            this.fetchData();
            if (this.currentPage === 1) {
                this.isFirstPage = true;
            }
        }
    }
    handleNextPage() {
        if (!this.disableNextButton) {
            this.currentPage++;
            this.showSpinner = true;
            this.fetchData();
            this.isFirstPage = false;
            
        }
    }
    
    handleLastPage() {
    const totalPages = Math.ceil(this.data.length / this.recLimit);
    this.currentPage = totalPages;
    this.fetchData();
    }


fetchData() {
    const offset = (this.currentPage - 1) * this.recLimit;

    getContactRecords({getUrl: this.recordId, offset: offset, recLimit: this.recLimit })
        .then((result) => {
            const startIndex = (this.currentPage - 1) * this.recLimit + 1;
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
            


            this.loading = false;
            this.isLastPage = result.length < this.recLimit;
            this.showSpinner = false; // Set showSpinner to false
            this.isTableVisible = true; // Set isTableVisible to true after fetching the data successfully
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