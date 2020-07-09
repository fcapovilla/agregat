// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"
import '@fortawesome/fontawesome-free/js/all'
import $ from 'jquery';
import 'bootstrap';

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

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
  scroll(e){
    if(this.pending == this.page() && this.scrollAt() > 90){
      this.pending = this.page() + 1
      this.pushEvent("load-more", {})
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
    this.active_id = null
    this.boundKeydown = this.keydown.bind(this)
    window.addEventListener("keydown", this.boundKeydown, false)
    window.addEventListener("resize", this.resize, false)
    document.querySelector('#item-list').focus()
  },
  updated(){
    this.resize()
    // Scroll to active item if it changed
    let active = this.el.querySelector('.item-container.active');
    if(active && this.active_id !== active.id) {
      active.scrollIntoView(true)
      this.active_id = active.id
    }
    document.querySelector('#item-list').focus()
  },
  destroyed(){
    window.removeEventListener("keydown", this.boundKeydown, false)
    window.removeEventListener("resize", this.resize, false)
  },
  keydown(e){
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
          this.pushEvent('next-item')
        }
      } else {
        this.pushEvent('next-item')
      }
    }
  },
  resize(){
    let itemList = document.querySelector('#item-list');
    itemList.style.height = (document.documentElement.clientHeight - itemList.getBoundingClientRect().top) + "px"
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket
