import Alpine from "../vendor/alpinejs-csp-3.5.2"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Define Phoenix hooks
let Hooks = {}

Hooks.FeedList = {
    mounted(){
        window.FeedListHook = this
    },
    updated(){
        let elem = this.el.querySelector(".feed-list .total-unread-count")
        if(elem) {
            document.title = "Agregat (" + elem.textContent + ")"
        }
    },
}

Hooks.ItemList = {
    mounted() {
        window.ItemListHook = this
    },
    updated() {
        document.querySelector('#item-list').dispatchEvent(new Event('updated'))
    }
}

// Define Alpine components
document.addEventListener('alpine:init', () => {
    Alpine.data('menu-bar', () => ({
        nextItem() {
            this.$dispatch('next-item')
        },
        previousItem() {
            this.$dispatch('previous-item')
        },
    }))

    Alpine.data('feed-list', () => ({
        style: {},

        init() {
            this.resize()
        },
        resize() {
            this.style.height = (document.documentElement.clientHeight - this.$root.getBoundingClientRect().top) + "px"
        },

        events: {
            ['@resize.window']() {
                this.resize()
            }
        },
        dragdrop: {
            ['@dragstart'](e) {
                e.dataTransfer.setData("text/plain", this.$el.id)
                this.$root.classList.add('dragging')
            },
            ['@dragend']() {
                this.$root.classList.remove('dragging')
            },
            ['@drop'](e) {
                window.FeedListHook.pushEvent('move-item', {item: e.dataTransfer.getData("text/plain"), destination: this.$el.id})
                this.$el.classList.remove('drag-hovered')
            },
            ['@dragenter.prevent']() {
                this.$el.classList.add('drag-hovered')
            },
            ['@dragleave.prevent']() {
                this.$el.classList.remove('drag-hovered')
            }
        }
    }))

    Alpine.data('item-list', () => ({
        style: {},
        selected: false,
        pending: false,

        init() {
            this.resize()
            this.$root.focus()
        },
        resize() {
            this.style.height = (document.documentElement.clientHeight - this.$root.getBoundingClientRect().top) + "px"
        },
        nextItem() {
            if (this.selected) {
                let next = this.selected.nextElementSibling
                if (next) {
                    next.dispatchEvent(new Event('select-item'))
                }
            } else {
                let first = this.$root.querySelector('.item-container')
                if (first) {
                    first.dispatchEvent(new Event('select-item'))
                }
            }
        },
        previousItem() {
            if (this.selected) {
                let previous = this.selected.previousElementSibling
                if (previous) {
                    previous.dispatchEvent(new Event('select-item'))
                }
            } else {
                let first = this.$root.querySelector('.item-container')
                if (first) {
                    first.dispatchEvent(new Event('select-item'))
                }
            }
        },

        events: {
            ['@resize.window']() {
                this.resize()
            },
            ['@scroll']() {
                let scrollAt = this.$root.scrollTop / (this.$root.scrollHeight - this.$root.clientHeight) * 100
                if(!this.pending && scrollAt > 90){
                    this.pending = true
                    window.ItemListHook.pushEvent("load-more")
                }
            },
            ['@updated']() {
                this.$root.focus()
                this.pending = false
            },
            ['@next-item.window']() {
                this.nextItem()
            },
            ['@previous-item.window']() {
                this.previousItem()
            },
            ['@keydown.j.window']() {
                this.nextItem()
            },
            ['@keydown.k.window']() {
                this.previousItem()
            },
            ['@keydown.n.window']() {
                let elem = document.querySelector("#items .item-container.active .item-content-title")
                if(elem && elem.href) {
                    window.open(elem.href, '_blank')
                }
            },
            ['@keydown.space.window']() {
                if(this.selected) {
                    let position = this.selected.getBoundingClientRect()
                    if(position.top + position.height - document.documentElement.clientHeight < 0) {
                        this.nextItem()
                    }
                } else {
                    this.nextItem()
                }
            },
        },
    }))

    Alpine.data('item', () => ({
        active() {
            return this.selected.id == this.$el.id ? "active" : null
        },
        selectItem() {
            this.selected = this.selected.id == this.$el.id ? false : this.$el
            if (this.selected) {
                window.requestAnimationFrame(() => {
                    this.$el.scrollIntoView()
                })
                window.ItemListHook.pushEventTo(this.$el, 'set-read', {read: true})
            }
        },
    }))
})

// Start Alpine
Alpine.start();
window.Alpine = Alpine;

// Start Phoenix LiveView
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
    params: {_csrf_token: csrfToken},
    hooks: Hooks,
    dom: {
        onBeforeElUpdated(from, to){
            if(from._x_dataStack){ window.Alpine.clone(from, to) }
        }
    }
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
