#! /usr/bin/env -S node --max-old-space-size=8192
import fs from 'fs/promises'

const geojson = JSON.parse(await fs.readFile(process.argv[2] + '.json'))

const newGeoJson = {"type": "FeatureCollection", "features": []}

newGeoJson.features = geojson.reduce((p,c) => {
  if (!c.properties?.way_area || !c.properties?.name) return p
  const newAttr = {}
  for (const key in c.properties) {
    if (c.properties[key] !== null && !newAttr[key.replace(':', '_').replace('name_', '_').toLowerCase()]) newAttr[key.replace(':', '_').replace('name_', '_').toLowerCase()] = c.properties[key]
  }
  c.properties = newAttr
  p.push(c)
  return p
}, [])

await fs.writeFile(process.argv[2] + '.json', JSON.stringify(newGeoJson, null, 4))
