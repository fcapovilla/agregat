import Alpine from "../vendor/alpinejs-csp-3.5.2"

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Define Phoenix hooks
let Hooks = {}

Hooks.InfiniteScroll = {
    mounted(){
        this.pending = this.page()
        this.boundScroll = this.scroll.bind(this)
        this.el.addEventListener("scroll", this.boundScroll, false)
    },
    updated(){
        this.pending = this.page()
    },
    destroyed() {
        this.el.removeEventListener('scroll', this.boundScroll, false)
    },
    page() {
        return this.el.dataset.page
    },
    scrollAt() {
        return this.el.scrollTop / (this.el.scrollHeight - this.el.clientHeight) * 100
    },
    scroll(){
        if(this.pending == this.page() && this.scrollAt() > 90){
            this.pending = this.page() + 1
            this.pushEvent("load-more")
        }
    }
}

Hooks.FeedList = {
    mounted(){
        window.FeedListHook = this
        window.dispatchEvent(new Event("resize"))
    },
    updated(){
        window.dispatchEvent(new Event("resize"))
        let elem = this.el.querySelector(".feed-list .total-unread-count")
        if(elem) {
            document.title = "Agregat (" + elem.textContent + ")"
        }
    },
}

Hooks.ItemList = {
    mounted() {
        window.ItemListHook = this
        window.dispatchEvent(new Event("resize"))
        document.querySelector('#item-list').focus()
    },
    updated() {
        window.dispatchEvent(new Event("resize"))
        document.querySelector('#item-list').focus()
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
        events: {
            ['@resize.window']() {
                this.$root.style.height = (document.documentElement.clientHeight - this.$root.getBoundingClientRect().top) + "px"
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
                window.FeedListHook.pushEventTo(this.$el, 'move-item', {item: e.dataTransfer.getData("text/plain"), destination: this.$el.id})
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
        selected: false,

        nextItem() {
            let active = this.$root.querySelector('.item-container.active')
            if (active) {
                let next = active.nextElementSibling
                if (next) {
                    next.dispatchEvent(new Event('select-item'))
                }
            } else {
                this.$root.querySelector('.item-container').dispatchEvent(new Event('select-item'))
            }
        },
        previousItem() {
            let active = this.$root.querySelector('.item-container.active')
            if (active) {
                let previous = active.previousElementSibling
                if (previous) {
                    previous.dispatchEvent(new Event('select-item'))
                }
            } else {
                this.$root.querySelector('.item-container').dispatchEvent(new Event('select-item'))
            }
        },
        events: {
            ['@resize.window']() {
                this.$root.style.height = (document.documentElement.clientHeight - this.$root.getBoundingClientRect().top) + "px"
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
                let active = this.$root.querySelector('.item-container.active')
                if(active) {
                    let position = active.getBoundingClientRect()
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
            return this.selected == this.$el.id ? "active" : null
        },
        selectItem() {
            this.selected = this.selected == this.$el.id ? false : this.$el.id
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
