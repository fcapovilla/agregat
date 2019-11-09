// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.scss"

import '@fortawesome/fontawesome-free/js/all'

import $ from 'jquery';

import 'bootstrap';

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"

let Hooks = {}

let scrollAt = () => {
  let scrollTop = document.documentElement.scrollTop || document.body.scrollTop
  let scrollHeight = document.documentElement.scrollHeight || document.body.scrollHeight
  let clientHeight = document.documentElement.clientHeight

  return scrollTop / (scrollHeight - clientHeight) * 100
}

Hooks.InfiniteScroll = {
  page() {
    return this.el.dataset.page
  },
  scroll(e){
    if(this.pending == this.page() && scrollAt() > 90){
      this.pending = this.page() + 1
      this.pushEvent("load-more", {})
    }
  },
  mounted(){
    this.pending = this.page()
    this.boundScroll = this.scroll.bind(this)
    window.addEventListener("scroll", this.boundScroll, false)
  },
  updated(){
    this.pending = this.page()
  },
  destroyed() {
    window.removeEventListener('scroll', this.boundScroll, false)
  }
}

Hooks.FeedList = {
  updated(){
    // Scroll to active item if it changed
    let elem = this.el.querySelector(".feed-list .total-unread-count")
    if(elem) {
      document.title = "Agregat (" + elem.textContent + ")"
    }
  },
}

Hooks.ItemList = {
  keydown(e){
    if (e.key == 'n') {
      let elem = document.querySelector("#items .item-container.active .item-content-title")
      if(elem && elem.href) {
        window.open(elem.href, '_blank')
      }
    }
  },
  mounted(){
    this.active_id = null
    window.addEventListener("keydown", this.keydown, false)
  },
  updated(){
    // Scroll to active item if it changed
    let active = this.el.querySelector('.item-container.active');
    if(active && this.active_id !== active.id) {
      active.scrollIntoView(true)
      this.active_id = active.id
    }
  },
  destroyed(){
    window.removeEventListener('keydown', this.keydown, false)
  }
}

let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks})
liveSocket.connect()
