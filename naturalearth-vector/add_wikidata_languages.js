#! /usr/bin/env node
import fs from 'fs/promises'

const geojson = JSON.parse(await fs.readFile(process.argv[2]))

const wikidata = JSON.parse(await fs.readFile('wikidata.json'))

geojson.features.forEach(c => {
  if (c.properties.wikidataid && wikidata[c.properties.wikidataid]) c.properties = {
    ...c.properties,
    ...wikidata[c.properties.wikidataid]
  }
})

await fs.writeFile(process.argv[2], JSON.stringify(geojson, null, 4))
