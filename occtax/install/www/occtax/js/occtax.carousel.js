class LizmapCarouselSlider extends HTMLElement {
    constructor() {
        super();

        this.currentSlide = null;
        this.slideCount = null;
        this.slides = null;
    }

    buildSlideHtmlFromChildElement(node) {
        let html = node.outerHTML;
        let alt = node.getAttribute("alt");
        let title = node.getAttribute("title");
        let newHtml = `
          <div class="liz-slide" data-attribution="${alt}" data-title="${title}">
            ${html}
          </div>
          `;

        return newHtml;
    }

    connectedCallback() {
        let newItemsHtml = [];
        let host = this.closest("lizmap-carousel-slider");
        Array.from(this.children).forEach(function (element) {
            let newItem = host.buildSlideHtmlFromChildElement(element);
            newItemsHtml.push(newItem);
        });

        // Modify inner HTML
        this.innerHTML = `
        <div class="liz-slider">
          ${newItemsHtml.join("\n")}
          <button class="liz-slide-btn liz-slide-btn-next"> > </button>
          <button class="liz-slide-btn liz-slide-btn-prev">
          < </button>
          <span class="liz-slide-attribution">Test</span>
        </div>
        `;

        // Current slide
        this.currentSlide = 0;

        // Compute the slides metrics and set CSS transform
        this.computeSlidesMetrics();

        // Set first attribution text
        if (this.slideCount > 0) {
            let attributionSpan = this.querySelector("span.liz-slide-attribution");
            let firstElement = this.querySelector("div.liz-slide");
            attributionSpan.textContent = firstElement.dataset.attribution;
        }

        // Add button events
        const nextButton = this.querySelector(".liz-slide-btn-next");
        const prevButton = this.querySelector(".liz-slide-btn-prev");

        // Add button click events
        nextButton.addEventListener("click", this.onChangeSlideButtonClick);
        prevButton.addEventListener("click", this.onChangeSlideButtonClick);

        // If there is only one image, hide the buttons
        this.toggleButtons();

        // Observe when new children are inserted
        var observer = new MutationObserver(function (mutations) {
            for (const { addedNodes } of mutations) {
                for (const node of addedNodes) {
                    if (!node.tagName) continue; // not an element
                    // Do not listen to the addition of liz-slide
                    // element to avoid infinite loop
                    if (!node.classList.contains("liz-slide")) {
                        host.onAddedChildren(node);
                    }
                }
            }
        });
        observer.observe(this, { childList: true });
    }

    computeSlidesMetrics() {
        // Select all slides
        this.slides = this.querySelectorAll(".liz-slide");

        // move slide by -100%
        this.slides.forEach((slide, indx) => {
            slide.style.transform = `translateX(${100 * (indx - this.currentSlide)
                }%)`;
        });

        // maximum number of slides
        this.slideCount = this.slides.length - 1;
    }

    toggleButtons() {
        // Add button events
        const nextButton = this.querySelector(".liz-slide-btn-next");
        const prevButton = this.querySelector(".liz-slide-btn-prev");

        // If there is only one image, hide the buttons
        nextButton.style.display = (this.slides.length < 2) ? "none" : 'block';
        prevButton.style.display = (this.slides.length < 2) ? "none" : 'block';
    }

    /**
     * Runs when the element is removed from the DOM
     */
    disconnectedCallback() {
        this.querySelector(".liz-slide-btn-next").removeEventListener(
            "click",
            this.onChangeSlideButtonClick
        );
        this.querySelector(".liz-slide-btn-prev").removeEventListener(
            "click",
            this.onChangeSlideButtonClick
        );
    }

    /**
     * Click on the next or prev buttons
     */
    onChangeSlideButtonClick(event) {
        // Check if this is tne prev or next button
        const usedButton = event.target;
        let isPrev = false;
        if (usedButton.classList.contains("liz-slide-btn-prev")) isPrev = true;

        // Get host component
        const host = event.target.closest("lizmap-carousel-slider");

        // check if current slide is the last and reset current slide
        let endReached = isPrev ? 0 : host.slideCount;
        let endReachedTargetSlide = isPrev ? host.slideCount : 0;
        if (host.currentSlide === endReached) {
            host.currentSlide = endReachedTargetSlide;
        } else {
            if (!isPrev) {
                host.currentSlide++;
            } else {
                host.currentSlide--;
            }
        }
        // move slide by -100%
        host.slides.forEach((slide, indx) => {
            slide.style.transform = `translateX(${100 * (indx - host.currentSlide)}%)`;
        });

        // Attribution
        host.setAttribution();
    }

    setAttribution() {
        // Change slide attribution
        let attributionSpan = this.querySelector("span.liz-slide-attribution");
        let activeElement = this.slides[this.currentSlide];
        if (activeElement) {
            let attribution = `${this.currentSlide + 1}/${this.slides.length} - ${activeElement.dataset.attribution}`;
            attributionSpan.textContent = attribution;
        }
    }

    onAddedChildren(node) {
        // Get the carousel webcomponent
        let host = this.closest("lizmap-carousel-slider");

        // Replace the new element by the div.liz-slide
        let html = host.buildSlideHtmlFromChildElement(node);
        host
            .querySelector("button.liz-slide-btn-next")
            .insertAdjacentHTML("beforebegin", html);

        // Remove the source image
        node.remove();

        // Recompute the slides metrics and position
        host.computeSlidesMetrics();

        // Display the buttons
        host.toggleButtons();

        // Attribution
        host.setAttribution();
    }
}

// Define the new web component
if ("customElements" in window) {
    customElements.define("lizmap-carousel-slider", LizmapCarouselSlider);
}

  // test
