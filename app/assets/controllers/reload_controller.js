import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { timeout: Number, url: String, defer: Boolean }
    static saveTimeout;

    connect() {
        // loadValue allows deferring startup
        if (!this.deferValue) {
            this.sendRequest();
        }
    }

    // deferred startup when the data-reload-load-value is changed
    deferValueChanged() {
        this.connect();
    }

    // change to the data-reload-timeout-value requires a reset
    timeoutValueChanged() {
        clearInterval(this.saveTimeout);
        if (this.timeoutValue > 0) {
            this.saveTimeout = setInterval(() => {
                // console.log("Sending");
                this.sendRequest();
            }, this.timeoutValue * 1000);
        }
    }

    // get new content from server
    sendRequest() {
        Rails.ajax({
            url: this.urlValue,
            type: 'get'//,
            // after the response is returned we re-run check to set the timeout again
            // success: () => { this.check(); }
        });
    }

    disconnect() {
        clearInterval(this.saveTimeout);
    }
}
