import './maps.black-component.js'
import syncMove from '@mapbox/mapbox-gl-sync-move'

// Taken from from https://github.com/maplibre/maplibre-gl-compare to work with our components
/**
 * @param {Object} a The first MapLibre GL Map
 * @param {Object} b The second MapLibre GL Map
 * @param {string|HTMLElement} container An HTML Element, or an element selector string for the compare container. It should be a wrapper around the two map Elements.
 * @param {Object} options
 * @param {string} [options.orientation=vertical] The orientation of the compare slider. `vertical` creates a vertical slider bar to compare one map on the left (map A) with another map on the right (map B). `horizontal` creates a horizontal slider bar to compare on mop on the top (map A) and another map on the bottom (map B).
 * @param {boolean} [options.mousemove=false] If `true` the compare slider will move with the cursor, otherwise the slider will need to be dragged to move.
 * @example
 * var compare = new maplibregl.Compare(beforeMap, afterMap, '#wrapper', {
 *   orientation: 'vertical',
 *   mousemove: true
 * });
 * @see [Swipe between maps](https://maplibre.org/maplibre-gl-js-docs/plugins/)
 */
function Compare(a, b, container, options) {
  this.options = options ? options : {};
  this._mapA = a;
  this._mapB = b;
  this._horizontal = this.options.orientation === "horizontal";
  this._onDown = this._onDown.bind(this);
  this._onMove = this._onMove.bind(this);
  this._onMouseUp = this._onMouseUp.bind(this);
  this._onTouchEnd = this._onTouchEnd.bind(this);
  this._swiper = document.createElement("div");
  this._swiper.className = this._horizontal
    ? "compare-swiper-horizontal"
    : "compare-swiper-vertical";

  this._controlContainer = document.createElement("div");
  this._controlContainer.className = this._horizontal
    ? "maplibregl-compare maplibregl-compare-horizontal"
    : "maplibregl-compare";
  this._controlContainer.className = this._controlContainer.className;
  this._controlContainer.appendChild(this._swiper);

  if (typeof container === "string" && document.body.querySelectorAll) {
    // get container with a selector
    var appendTarget = document.body.querySelectorAll(container)[0];
    if (!appendTarget) {
      throw new Error("Cannot find element with specified container selector.");
    }
    appendTarget.appendChild(this._controlContainer);
  } else if (container instanceof Element && container.appendChild) {
    // get container directly
    container.appendChild(this._controlContainer);
  } else {
    throw new Error(
      "Invalid container specified. Must be CSS selector or HTML element."
    );
  }

  this._bounds = b.getContainer().getBoundingClientRect();
  var swiperPosition =
    (this._horizontal ? this._bounds.height : this._bounds.width) / 2;

  this._setPosition(swiperPosition);

  this._clearSync = syncMove(a, b);
  this._onResize = function () {
    this._bounds = b.getContainer().getBoundingClientRect();
    if (this.currentPosition) this._setPosition(this.currentPosition);
  }.bind(this);

  // b.on("resize", this._onResize);

  if (this.options && this.options.mousemove) {
    a.getContainer().addEventListener("mousemove", this._onMove);
    b.getContainer().addEventListener("mousemove", this._onMove);
  }

  this._swiper.addEventListener("mousedown", this._onDown);
  this._swiper.addEventListener("touchstart", this._onDown);
}

Compare.prototype = {
  _setPointerEvents: function (v) {
    this._controlContainer.style.pointerEvents = v;
    this._swiper.style.pointerEvents = v;
  },

  _onDown: function (e) {
    if (e.touches) {
      document.addEventListener("touchmove", this._onMove);
      document.addEventListener("touchend", this._onTouchEnd);
    } else {
      document.addEventListener("mousemove", this._onMove);
      document.addEventListener("mouseup", this._onMouseUp);
    }
  },

  _setPosition: function (x) {
    x = Math.min(
      x,
      this._horizontal ? this._bounds.height : this._bounds.width
    );
    var pos = this._horizontal
      ? "translate(0, " + x + "px)"
      : "translate(" + x + "px, 0)";
    this._controlContainer.style.transform = pos;
    this._controlContainer.style.WebkitTransform = pos;
    var clipA = this._horizontal
      ? "rect(0, 999em, " + x + "px, 0)"
      : "rect(0, " + x + "px, " + this._bounds.height + "px, 0)";
    var clipB = this._horizontal
      ? "rect(" + x + "px, 999em, " + this._bounds.height + "px,0)"
      : "rect(0, 999em, " + this._bounds.height + "px," + x + "px)";

    this._mapA.getContainer().getRootNode().host.style.clip = clipA;
    this._mapB.getContainer().getRootNode().host.style.clip = clipB;
    this.currentPosition = x;
  },

  _onMove: function (e) {
    if (this.options && this.options.mousemove) {
      this._setPointerEvents(e.touches ? "auto" : "none");
    }

    this._horizontal
      ? this._setPosition(this._getY(e))
      : this._setPosition(this._getX(e));
  },

  _onMouseUp: function () {
    document.removeEventListener("mousemove", this._onMove);
    document.removeEventListener("mouseup", this._onMouseUp);
  },

  _onTouchEnd: function () {
    document.removeEventListener("touchmove", this._onMove);
    document.removeEventListener("touchend", this._onTouchEnd);
  },

  _getX: function (e) {
    e = e.touches ? e.touches[0] : e;
    var x = e.clientX - this._bounds.left;
    if (x < 0) x = 0;
    if (x > this._bounds.width) x = this._bounds.width;
    return x;
  },

  _getY: function (e) {
    e = e.touches ? e.touches[0] : e;
    var y = e.clientY - this._bounds.top;
    if (y < 0) y = 0;
    if (y > this._bounds.height) y = this._bounds.height;
    return y;
  },

  /**
   * Set the position of the slider.
   *
   * @param {number} x Slider position in pixels from left/top.
   */
  setSlider: function (x) {
    this._setPosition(x);
  },

  remove: function () {
    this._clearSync();
    this._mapB.off("resize", this._onResize);
    var aContainer = this._mapA.getContainer();

    if (!!aContainer) {
      aContainer.getRootNode().host.style.clip = null;
      aContainer.removeEventListener("mousemove", this._onMove);
    }

    var bContainer = this._mapB.getContainer();

    if (!!bContainer) {
      bContainer.getRootNode().host.style.clip = null;
      bContainer.removeEventListener("mousemove", this._onMove);
    }

    this._swiper.removeEventListener("mousedown", this._onDown);
    this._swiper.removeEventListener("touchstart", this._onDown);
    this._controlContainer.remove();
  },
};

const comparisonContainer = document.querySelector('.comparisonContainer')
const demomap = document.querySelector('.demomap')
const togglecompare = document.querySelector('.togglecompare')
let styleswitch2
let demomap2
let firstmap
let secondmap
let compare
let compareMode = false

const styleswitch = document.querySelector('.styleswitch')
styleswitch.value = 'openstreetmap-protomaps/protomaps/grayscale'
styleswitch.addEventListener('change', (e) => {
  demomap.setAttribute('mapstyle', e.target.value)
})

const terrain = document.querySelector('#terrain')
terrain.checked = true
terrain.setAttribute('checked', '')
terrain.addEventListener('change', (e) => {
  demomap.setAttribute('terrain', !!terrain.checked)
  if (demomap2) demomap2.setAttribute('terrain', !!terrain.checked)
})

const hillshade = document.querySelector('#hillshade')
hillshade.checked = true
hillshade.setAttribute('checked', '')
hillshade.addEventListener('change', (e) => {
  demomap.setAttribute('hillshade', !!hillshade.checked)
  if (demomap2) demomap2.setAttribute('hillshade', !!hillshade.checked)
})

const contours = document.querySelector('#contours')
contours.checked = false
contours.addEventListener('change', (e) => {
  demomap.setAttribute('contours', !!contours.checked)
  if (demomap2) demomap2.setAttribute('contours', !!contours.checked)
})

const globe = document.querySelector('#globe')
globe.checked = false
globe.addEventListener('change', (e) => {
  demomap.setAttribute('globe', !!globe.checked)
  if (demomap2) demomap2.setAttribute('globe', !!globe.checked)
})

const startCompare = () => {
  if (firstmap && secondmap && compareMode) {
    if (compare) compare.remove()
    compare = new Compare(firstmap, secondmap, comparisonContainer)
  }
}
demomap.addEventListener('map', (e) => {
  firstmap = e.detail.map;
  startCompare()
})
togglecompare.addEventListener('click', () => {
  if (compareMode) {
    compareMode = false
    togglecompare.textContent = "Compare styles"
    compare.remove()
    demomap2.remove()
    styleswitch2.remove()
    demomap2 = null
  } else {
    compareMode = true
    togglecompare.textContent = "Stop comparison"
    demomap2 = demomap.cloneNode()
    demomap2.setAttribute('mapstyle', 'openstreetmap-openmaptiles/nst-guide/liberty-topo')
    demomap2.addEventListener('map', (e) => {
      secondmap = e.detail.map
      startCompare()
    })
    comparisonContainer.appendChild(demomap2)

    styleswitch2 = styleswitch.cloneNode(true)
    styleswitch2.value = 'openstreetmap-openmaptiles/nst-guide/liberty-topo'
    styleswitch2.addEventListener('change', (e) => { demomap2.setAttribute('mapstyle', e.target.value) })
    togglecompare.after(styleswitch2)
  }
})

if (window.location.href.includes('github.io')) {
  document.querySelector('.githubWarning').style.display = 'block'
  demomap.setAttribute('loader', 'pmtiles')
}
