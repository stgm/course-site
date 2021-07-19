// Very roughly based on https://stevepolito.design/blog/rails-auto-save-form-data/

import { Controller } from "stimulus"

export default class extends Controller {
    static targets = [ "form" ]

    connect() {
        // Create a unique key to store the form data into localStorage.
        // This could be anything as long as it's unique.
        // https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage
        this.localStorageKey = window.location
        // Retrieve data from localStorage when the Controller loads.
        this.restoreFormData();
    }

    clearLocalStorage() {
        // See if there is data stored for this particular form.
        if(localStorage.getItem(this.localStorageKey) != null) {
            // Clear data from localStorage when the form is submitted.
            localStorage.removeItem(this.localStorageKey);
        }
    }

    getFormData() {
        let data = {};

        // selected all basic textual form elements
        const entries = Array.from(this.formTarget.elements).filter(
            e => ['text', 'textarea'].includes(e.type)
        );

        // store key-value pairs for all selected elements
        for(var entry of entries) {
            data[entry.name] = entry.value;
        }

        // convert to object
        return data;
    }

    saveToLocalStorage() {
        const data = this.getFormData();
        // Save the form data into localStorage. We need to convert the data Object into a String.
        localStorage.setItem(this.localStorageKey, JSON.stringify(data));
    }

    restoreFormData() {
        // See if there is data stored for this particular form.
        if(localStorage.getItem(this.localStorageKey) != null) {
            // We need to convert the String of data back into an Object.
            const data = JSON.parse(localStorage.getItem(this.localStorageKey));
            // This allows us to have access to this.formTarget in the loop below.
            const form = this.formTarget;
            // Loop through each key/value pair and set the value on the corresponding form field.
            Object.entries(data).forEach((entry)=>{
                let name    = entry[0];
                let value   = entry[1];
                let input   = form.querySelector(`[name='${name}']`);
                input && (input.value = value);
            })
        }
    }
}
