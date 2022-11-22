class InlineSelect extends HTMLElement {
    sourceSelectId = null;
    sourceSelectItem = null;
    inlineSelectDivId = null;

    constructor() {
        super();

        // Get source select ID
        let source = this.getAttribute("source");
        if (!source) {
            return;
        }
        this.sourceSelectId = source;
        this.inlineSelectDivId = `inline-select-${this.sourceSelectId}`;

        // Get the source select item
        let selectItem = document.getElementById(this.sourceSelectId);
        if (!selectItem) {
            return;
        }
        this.sourceSelectItem = selectItem;

        // Read the attribute label to see if we must
        // use the option text or the option value
        // as a label.
        let label = this.getAttribute("label");
        if (!label) {
            label = "text";
        }

        // Additional classes to add to the children
        let classes = this.getAttribute("class");
        if (!classes) {
            classes = "";
        }

        // Max span on a line
        let maxCols = this.getAttribute("max-cols");
        if (!maxCols) {
            maxCols = "-1";
        }

        // Render HTML
        this.getHTML(label, classes, maxCols);

        // Hide the parent select item
        this.sourceSelectItem.style.display = 'none';
    }

    /**
     * Build the inline-select content
     * from the source native select
     */
    getHTML(label, classes, maxCols) {
        // Loop through the options and create dedicated spans
        let spans = [];
        Array.from(this.sourceSelectItem.options).map(function (option, index) {
            let itemLabel = "";
            if (label == "value") {
                itemLabel = option.value;
            } else if (label == "text") {
                itemLabel = option.text;
            }
            let breakLine = '';
            if (maxCols != -1 && index == maxCols) {
                breakLine = '</br>';
            }
            spans.push(
                `\n    <span  class="inline-select-option ${classes}" data-value="${option.value}" data-tooltip="${option.text}">${itemLabel}</span>${breakLine}`
            );
        });

        // Build HTML
        let html = `
          <div id="${this.inlineSelectDivId
            }" class="inline-select" data-select="${this.sourceSelectItem.id}">
            ${spans.join("")}
          </div>
          `;

        // Set the content
        this.innerHTML = html;

        // Set the active values corresponding to the selected options
        this.setValues(this.getSourceSelectValues());
    }

    /**
     * Get the values of the active .inline-select-option element
     * items contained inside an div.inline-select
     *
     * param {string} selectDivId - Id of the selectDiv item
     * return {array} The list of active values
     */
    getValues() {
        let inlineSelectDiv = document.getElementById(this.inlineSelectDivId);
        if (!inlineSelectDiv) return;
        let selectedValues = Array.from(inlineSelectDiv.children)
            .filter(function (element) {
                return element.classList.contains("active");
            })
            .map(function (element) {
                return element.dataset.value;
            });

        return selectedValues;
    }

    /**
     * Set the active element of an div.inline-select
     *
     * @param {array} List of values to activate
     */
    setValues(values) {
        let inlineSelectDiv = document.getElementById(this.inlineSelectDivId);
        if (!inlineSelectDiv) return;
        Array.from(inlineSelectDiv.children).forEach(function (element) {
            element.classList.toggle(
                "active",
                values.includes(element.dataset.value)
            );
        });
    }

    /**
     * Get the values of a native HTML select input
     * with a multiple attribute
     *
     * return {array} The list of active values
     */
    getSourceSelectValues() {
        let selected = Array.from(this.sourceSelectItem.options)
            .filter(function (option) {
                return option.selected;
            })
            .map(function (option) {
                return option.value;
            });
        return selected;
    }

    /**
     * Set the values of of native HTML multiple select item
     * based on the corresponding div.inlineSelect
     */
    setSourceSelectValues() {
        // Get the values of the active elements
        let values = this.getValues();
        let sourceSelect = document.getElementById(this.sourceSelectId);
        if (!sourceSelect) return;

        // Set the HTML select options to selected
        // accordingly
        Array.from(sourceSelect.options).forEach(function (option) {
            option.selected = values.includes(option.value);
        });
    }

    onSourceItemChange() {
        // Get the selected options
        let selectedValues = Array.from(this.selectedOptions).map(function (
            option
        ) {
            return option.value;
        });

        // Get the corresponding inlineSelect item
        let sourceSelectItem = document.querySelector(
            `inline-select[source=${this.id}]`
        );

        // Set the values accordingly
        sourceSelectItem.setValues(selectedValues);
    }

    /**
     * Handle click events
     * @param  {Event} event The event object
     */
    childSpanClickHandler(event) {
        // Set the active class
        let isActive = this.classList.contains("active");
        this.classList.toggle("active", !isActive);

        // Get the host component
        let host = event.target.closest("inline-select");

        // Refresh the corresponding HTML select
        host.setSourceSelectValues();
    }

    /**
     * Runs each time the element is appended to or moved in the DOM
     */
    connectedCallback() {
        // Get the div container component
        let inlineSelectDiv = document.getElementById(this.inlineSelectDivId);
        let spans = inlineSelectDiv.getElementsByClassName("inline-select-option");

        // Attach click handler to each child span
        let self = this;
        Array.from(spans).forEach(function (element) {
            element.addEventListener("click", self.childSpanClickHandler);
        });

        // Attach source select change
        this.sourceSelectItem.addEventListener("change", this.onSourceItemChange);
    }

    /**
     * Runs when the element is removed from the DOM
     */
    disconnectedCallback() {
        // Get the div container component
        let inlineSelectDiv = document.getElementById(this.inlineSelectDivId);
        let spans = inlineSelectDiv.getElementsByClassName("inline-select-option");

        // Remove click handler from each child span
        let self = this;
        Array.from(spans).forEach(function (element) {
            element.removeEventListener("click", self.childSpanClickHandler);
        });

        // Remove source select connected change event
        this.sourceSelectItem.removeEventListener("change", this.onSourceItemChange);
    }

}

// Define the new web component
if ("customElements" in window) {
    customElements.define("inline-select", InlineSelect);
}
