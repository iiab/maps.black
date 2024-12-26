#! /usr/bin/env node
import { area } from '@turf/area'
import fs from 'fs/promises'

const geojson = JSON.parse(await fs.readFile(process.argv[2]))

geojson.features.forEach(e => { if (e?.geometry?.type === 'Polygon' || e?.geometry?.type === 'MultiPolygon') {e.properties.way_area = Math.floor(area(e.geometry)) || 0} })

await fs.writeFile(process.argv[2], JSON.stringify(geojson, null, 4))
