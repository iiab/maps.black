import { createDbWorker } from "sql.js-httpvfs"
import workerBundle from "sql.js-httpvfs/dist/sqlite.worker.js.bin"
import wasmBundle from "sql.js-httpvfs/dist/sql-wasm.wasm"
import { decompressSync } from "fflate";

const sqlitePools = {}

const createWorker = (url, requestChunkSize = 4096) => createDbWorker(
  [{
    from: "inline",
    config: {
      serverMode: "full",
      requestChunkSize,
      url,
    }
  }],
  workerBundle,
  wasmBundle,
)

export const addMbtilesProtocol = maplibregl => maplibregl.addProtocol('mbtiles', async (params, abortController) => {
  const url = new URL(params.url)
  const searchParams = url.searchParams
  url.search = ''
  url.protocol = 'https'
  const remoteURL = url.toString()

  if (!sqlitePools[remoteURL]) sqlitePools[remoteURL] = createWorker(remoteURL)

  const result = await (await sqlitePools[remoteURL]).db.exec(
    'SELECT tile_data FROM tiles WHERE zoom_level = $zoom AND tile_column = $col AND tile_row = $row',
    { $zoom: searchParams.z, $col: searchParams.x, $row: searchParams.y }
  )
  return { data: decompressSync(new Uint8Array(result[0].values[0])) };
  //   const buffer = await t.arrayBuffer()
  //   return { data: buffer }
})
