#!/usr/bin/env node
import { layersWithCustomTheme } from "protomaps-themes-base"
import fs from "node:fs/promises"

import bio from "./themes/bio.js"
import black_and_white from "./themes/black_and_white.js"
import iris_bloom from "./themes/iris_bloom.js"
import seafoam from "./themes/seafoam.js"
import sol from "./themes/sol.js"
import dusk_rose from "./themes/dusk_rose.js"
import rainforest from "./themes/rainforest.js"

const themes = { bio, black_and_white, iris_bloom, seafoam, dusk_rose, rainforest }

await Promise.all(Object.entries(themes).map(async ([name, theme]) => {
  await fs.mkdir(`../protomaps/protomaps/${name}`, { recursive: true })
  await fs.writeFile(`../protomaps/protomaps/${name}/style.json`, JSON.stringify({
    version: 8,
    name: `openstreetmap protomaps ${name}`,
    glyphs: "https://maps.black/fonts/{fontstack}/{range}.pbf",
    sources: {
      protomaps: {
        type: "vector",
        url: "https://maps.black/openstreetmap-protomaps/{z}/{x}/{y}.pbf",
      }
    },
    layers: layersWithCustomTheme("protomaps", theme, "en")
  }, null, 4))
}))
