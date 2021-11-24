// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
import './jquery-global.js'
import '@fortawesome/fontawesome-free/js/all'
import 'bootstrap'
import Alpine from "../vendor/alpinejs-csp-3.5.2"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

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
        window.addEventListener("resize", this.resize, false)
        this.resize()
    },
    updated(){
        this.resize()
        let elem = this.el.querySelector(".feed-list .total-unread-count")
        if(elem) {
            document.title = "Agregat (" + elem.textContent + ")"
        }
    },
    destroyed(){
        window.removeEventListener("resize", this.resize, false)
    },
    resize(){
        let feedList = document.querySelector('.feed-list');
        feedList.style.height = (document.documentElement.clientHeight - feedList.getBoundingClientRect().top) + "px"
    }
}

Hooks.ItemList = {
    mounted(){
        this.resize()
        this.boundKeydown = this.keydown.bind(this)
        this.boundBtnNextItem = this.nextItem.bind(this)
        this.boundBtnPreviousItem = this.previousItem.bind(this)
        window.addEventListener("keydown", this.boundKeydown, false)
        window.addEventListener("resize", this.resize, false)
        document.querySelector('#btn-previous-item').addEventListener("click", this.boundBtnPreviousItem, false)
        document.querySelector('#btn-next-item').addEventListener("click", this.boundBtnNextItem, false)
        document.querySelector('#item-list').focus()
    },
    updated(){
        this.resize()
        document.querySelector('#item-list').focus()
    },
    destroyed(){
        window.removeEventListener("keydown", this.boundKeydown, false)
        window.removeEventListener("resize", this.resize, false)
        document.querySelector('#btn-previous-item').removeEventListener("click", this.boundBtnPreviousItem, false)
        document.querySelector('#btn-next-item').removeEventListener("click", this.boundBtnNextItem, false)
    },
    keydown(e){
        if (e.key == 'j') {
            this.nextItem()
        }
        if (e.key == 'k') {
            this.previousItem()
        }
        if (e.key == 'n') {
            let elem = document.querySelector("#items .item-container.active .item-content-title")
            if(elem && elem.href) {
                window.open(elem.href, '_blank')
            }
        }
        if (e.key == ' ') {
            let active = this.el.querySelector('.item-container.active')
            if(active) {
                let position = active.getBoundingClientRect()
                if(position.top + position.height - document.documentElement.clientHeight < 0) {
                    this.nextItem()
                }
            } else {
                this.nextItem()
            }
        }
    },
    resize(){
        let itemList = document.querySelector('#item-list');
        itemList.style.height = (document.documentElement.clientHeight - itemList.getBoundingClientRect().top) + "px"
    },
    nextItem(){
        let active = this.el.querySelector('.item-container.active')
        if (active) {
            let next = active.nextElementSibling
            if (next) {
                next.dispatchEvent(new Event('select-item'))
            }
        } else {
            this.el.querySelector('.item-container').dispatchEvent(new Event('select-item'))
        }
    },
    previousItem(){
        let active = this.el.querySelector('.item-container.active')
        if (active) {
            let previous = active.previousElementSibling
            if (previous) { 
                previous.dispatchEvent(new Event('select-item'))
            }
        } else {
            this.el.querySelector('.item-container').dispatchEvent(new Event('select-item'))
        }
    }
}

Hooks.Item = {
    mounted(){
        this.el.addEventListener('select-item', () => {
            if(!this.el.classList.contains('active')) {
                this.pushEventTo(this.el, 'set-read', {read: true})
            }
        })
    },
}

// Define Alpine components
document.addEventListener('alpine:init', () => {
    Alpine.data('item-list', () => ({
        selected: false
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
