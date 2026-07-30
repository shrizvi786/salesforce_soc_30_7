import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getHtmlPageFlag from '@salesforce/apex/HtmlApiController.getHtmlPageFlag';
import setHtmlPageFlag from '@salesforce/apex/HtmlApiController.setHtmlPageFlag';
import getRecordName from '@salesforce/apex/HtmlApiController.getRecordName';
import submitHtmlChart from '@salesforce/apex/HtmlApiController.submitHtmlChart';
import fetchHtmlChart from '@salesforce/apex/HtmlApiController.fetchHtmlChart';
import getPageData from '@salesforce/apex/HtmlApiController.getPageData';

const PAGE_DATA_URL = 'https://dashboard-api.solvedconsulting.net/production/html-charts/get-page-data';

export default class HtmlApiIntegration extends LightningElement {
    @api recordId;
    @api objectApiName;

    chartTitle = '';
    htmlCode = '';
    showFilters = true;
    hasQuery = false;
    queryStr = '';

    isLoading = true;
    hasHtmlPage = false;
    dataFetched = false;
    flagLoaded = false;

    // Page data panel
    showPageDataPanel = false;
    pageDataCurlCmd = '';
    pageDataResponse = '';
    copied = false;
    copiedJson = false;

    async connectedCallback() {
        await Promise.all([
            this.loadHtmlPageFlag(),
            this.loadRecordName()
        ]);
    }

    async loadHtmlPageFlag() {
        this.isLoading = true;
        try {
            const result = await getHtmlPageFlag({ recordId: this.recordId });
            this.hasHtmlPage = result === true;
        } catch (e) {
            this.hasHtmlPage = false;
        }
        this.flagLoaded = true;
        this.isLoading = false;
    }

    async loadRecordName() {
        try {
            this.chartTitle = await getRecordName({ recordId: this.recordId });
        } catch (e) {
            this.chartTitle = this.recordId;
        }
    }

    // ── Visibility getters ──────────────────────────────────────────────────
    get showFetchFirst() {
        return this.flagLoaded && this.hasHtmlPage && !this.dataFetched;
    }

    get showForm() {
        return this.flagLoaded && !this.hasHtmlPage && !this.dataFetched;
    }

    get showFormAfterFetch() {
        return this.flagLoaded && this.dataFetched;
    }

    get isSubmitDisabled() {
        return this.isLoading || !this.htmlCode;
    }

    get copyBtnLabel() {
        return this.copied ? 'Copied!' : 'Copy';
    }

    get copyJsonBtnLabel() {
        return this.copiedJson ? 'Copied!' : 'Copy JSON';
    }

    // ── Field change handlers ───────────────────────────────────────────────
    handleHtmlChange(event)        { this.htmlCode   = event.detail.value; }
    handleShowFiltersChange(event) { this.showFilters = event.target.checked; }

    handleQueryToggleChange(event) {
        this.hasQuery = event.target.checked;
        this.autoFillHtml();
    }

    handleQueryChange(event) {
        this.queryStr = event.detail.value;
        this.autoFillHtml();
    }

    // Auto-fill HTML Code with "<p>In Progress</p>" when:
    //   • HTML Code is blank
    //   • Query toggle is ON
    //   • SQL Query has a value
    autoFillHtml() {
        if (!this.htmlCode && this.hasQuery && this.queryStr) {
            this.htmlCode = '<p>In Progress</p>';
        }
    }

    // ── Submit ──────────────────────────────────────────────────────────────
    async handleSubmit() {
        if (!this.htmlCode) {
            this.showToast('Validation', 'Please enter HTML Code.', 'warning');
            return;
        }

        this.isLoading = true;
        this.showPageDataPanel = false;

        try {
            const result = await submitHtmlChart({
                recordId:     this.recordId,
                action:       'upsert',
                htmlBody:     this.htmlCode,
                widthPercent: 100,
                sortOrder:    1,
                isActive:     true,
                chartTitle:   this.chartTitle,
                htmlChartTab: null,
                showFilters:  this.showFilters,
                queryStr:     this.hasQuery ? this.queryStr : null
            });

            const parsed = JSON.parse(result);
            const body = parsed.body || parsed;
            const msg = body.message || 'Chart submitted successfully';

            if (!this.hasHtmlPage) {
                await this.markHtmlPageTrue();
            }

            // Keep form visible in STATE 3
            this.dataFetched = true;

            this.showToast('Success', msg, 'success');

            if (this.hasQuery && this.queryStr) {
                await this.loadPageData();
            } else {
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => { window.location.reload(); }, 1500);
            }
        } catch (error) {
            this.showToast('Error', this.reduceErrors(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ── Fetch current chart ─────────────────────────────────────────────────
    async handleFetch() {
        this.isLoading = true;
        this.showPageDataPanel = false;

        try {
            const result = await fetchHtmlChart({ sfId: this.recordId });
            const parsed = JSON.parse(result);
            const body = parsed.body || parsed;

            this.htmlCode    = body.Chart_HTML__c || this.htmlCode;
            this.showFilters = body.Show_Filters__c === true;

            const fetchedQuery = body.Query__c || '';
            if (fetchedQuery) {
                this.hasQuery = true;
                this.queryStr = fetchedQuery;
            } else {
                this.hasQuery = false;
                this.queryStr = '';
            }

            this.dataFetched = true;
            this.showToast('Success', 'Chart data loaded successfully.', 'success');

            // If query is set, also call get-page-data
            if (this.hasQuery && this.queryStr) {
                await this.loadPageData();
            }
        } catch (error) {
            this.showToast('Error', this.reduceErrors(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ── Load page data ──────────────────────────────────────────────────────
    async loadPageData() {
        try {
            const rawResponse = await getPageData({ sfId: this.recordId });

            this.pageDataCurlCmd = PAGE_DATA_URL;

            try {
                this.pageDataResponse = JSON.stringify(JSON.parse(rawResponse), null, 2);
            } catch (e) {
                this.pageDataResponse = rawResponse;
            }

            this.showPageDataPanel = true;
        } catch (error) {
            this.showToast(
                'Warning',
                'Saved but failed to fetch page data: ' + this.reduceErrors(error),
                'warning'
            );
        }
    }

    async markHtmlPageTrue() {
        try {
            await setHtmlPageFlag({ recordId: this.recordId });
            this.hasHtmlPage = true;
        } catch (error) {
            this.showToast(
                'Warning',
                'Chart saved but failed to update Html_Page__c: ' + this.reduceErrors(error),
                'warning'
            );
        }
    }

    // ── Export All — single TXT file with SFID + Endpoint + JSON ──────────
    handleExportAll() {
        try {
            const content =
                'SFID: ' + this.recordId + '\n\n' +
                'Endpoint: ' + this.pageDataCurlCmd + '\n\n' +
                'JSON Response:\n' + this.pageDataResponse;

            this.triggerDownload(
                content,
                'text/plain',
                'export-' + this.recordId + '.txt'
            );
        } catch (e) {
            this.showToast('Error', 'Could not export: ' + e.message, 'error');
        }
    }

    // ── Single copy handler — copies curl command + API response ───────────
    handleCopy() {
        const text = this.pageDataCurlCmd + '\n\n' + this.pageDataResponse;
        this.copyToClipboard(text);
        this.copied = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => { this.copied = false; }, 2000);
    }

    // ── Copy just the JSON response ─────────────────────────────────────────
    handleCopyJson() {
        this.copyToClipboard(this.pageDataResponse);
        this.copiedJson = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => { this.copiedJson = false; }, 2000);
    }

    // ── Download JSON + TXT files ───────────────────────────────────────────
    handleDownloadJson() {
        try {
            const base = 'page-data-' + this.recordId;

            // 1. JSON file — response only
            this.triggerDownload(
                this.pageDataResponse,
                'application/json',
                base + '.json'
            );

            // 2. TXT file — endpoint + response (same as Copy button)
            this.triggerDownload(
                this.pageDataCurlCmd + '\n\n' + this.pageDataResponse,
                'text/plain',
                base + '.txt'
            );
        } catch (e) {
            this.showToast('Error', 'Could not download files: ' + e.message, 'error');
        }
    }

    triggerDownload(content, mimeType, filename) {
        const blob = new Blob([content], { type: mimeType });
        const url  = URL.createObjectURL(blob);
        const a    = document.createElement('a');
        a.href     = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    handleDone() {
        window.location.reload();
    }

    // ── Utilities ───────────────────────────────────────────────────────────
    copyToClipboard(text) {
        try {
            navigator.clipboard.writeText(text);
        } catch (e) {
            const ta = document.createElement('textarea');
            ta.value = text;
            ta.style.cssText = 'position:fixed;top:0;left:0;opacity:0;';
            document.body.appendChild(ta);
            ta.focus();
            ta.select();
            try { document.execCommand('copy'); } catch (_) { /* ignore */ }
            document.body.removeChild(ta);
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceErrors(error) {
        if (typeof error === 'string') return error;
        if (error?.body?.message) return error.body.message;
        if (error?.message) return error.message;
        return 'An unexpected error occurred.';
    }
}