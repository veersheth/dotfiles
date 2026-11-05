// Adapted from GNOME Shell's unaligned overview layout: keep a common scale,
// group by original vertical position, and order each row horizontally.
function spreadCaptures(captures, monitors) {
    const spacing = 24
    const maxScale = 0.95

    for (const monitor of monitors) {
      for (const workspaceId of [...new Set(captures.filter(c => c.monitorId === monitor.id).map(c => c.workspaceId))]) {
        const windows = captures.filter(c => c.monitorId === monitor.id && c.workspaceId === workspaceId)
        if (windows.length === 0) continue

        const screenWidth = monitor.width / monitor.scale
        const screenHeight = monitor.height / monitor.scale
        const margin = Math.min(48, Math.min(screenWidth, screenHeight) * 0.04)
        const areaWidth = screenWidth - 2 * margin
        const topMargin = Math.min(158, screenHeight * 0.16)
        const areaHeight = screenHeight - topMargin - margin
        const smallWindowScale = w => 1.5 - 0.5 * Math.min(1, w.height / screenHeight)
        const ordered = windows.slice().sort((a, b) =>
            (a.y + a.height / 2) - (b.y + b.height / 2)
            || (a.x + a.width / 2) - (b.x + b.width / 2)
            || a.className.localeCompare(b.className)
            || a.address.localeCompare(b.address))
        const totalWidth = ordered.reduce((sum, w) =>
            sum + w.width * smallWindowScale(w), 0)
        let best = null

        for (let rowCount = 1; rowCount <= windows.length; rowCount++) {
            const idealWidth = totalWidth / rowCount
            const rows = []
            let next = 0

            for (let rowIndex = 0; rowIndex < rowCount; rowIndex++) {
                const row = { windows: [], width: 0, height: 0 }
                const remainingRows = rowCount - rowIndex - 1
                while (next < ordered.length - remainingRows) {
                    const window = ordered[next]
                    const width = window.width * smallWindowScale(window)
                    if (row.windows.length > 0 && rowIndex < rowCount - 1
                            && Math.abs(idealWidth - row.width)
                               < Math.abs(idealWidth - row.width - width))
                        break
                    row.windows.push(window)
                    row.width += width
                    row.height = Math.max(row.height,
                        window.height * smallWindowScale(window))
                    next++
                }
                row.windows.sort((a, b) =>
                    (a.x + a.width / 2) - (b.x + b.width / 2)
                    || a.className.localeCompare(b.className)
                    || a.address.localeCompare(b.address))
                rows.push(row)
            }

            const maxWidth = Math.max(...rows.map(row => row.width))
            const maxColumns = Math.max(...rows.map(row => row.windows.length))
            const totalHeight = rows.reduce((sum, row) => sum + row.height, 0)
            const scale = Math.min(maxScale,
                (areaWidth - (maxColumns - 1) * spacing) / maxWidth,
                (areaHeight - (rowCount - 1) * spacing) / totalHeight)
            if (scale <= 0) continue

            const usedWidth = maxWidth * scale + (maxColumns - 1) * spacing
            const usedHeight = totalHeight * scale + (rowCount - 1) * spacing
            const space = usedWidth * usedHeight / (areaWidth * areaHeight)
            const score = scale + 0.1 * space
            if (!best || score > best.score)
                best = { rows, scale, usedHeight, score }
        }
        if (!best) continue

        let y = topMargin + (areaHeight - best.usedHeight) / 2
        for (const row of best.rows) {
            const rowHeight = row.height * best.scale
            const rowWidth = row.width * best.scale
                + (row.windows.length - 1) * spacing
            let x = (screenWidth - rowWidth) / 2

            for (const window of row.windows) {
                const cellScale = smallWindowScale(window) * best.scale
                const cloneScale = Math.min(maxScale, cellScale)
                const cellWidth = window.width * cellScale
                const cloneWidth = window.width * cloneScale
                const cloneHeight = window.height * cloneScale
                window.targetX = x + (cellWidth - cloneWidth) / 2
                window.targetY = best.rows.length === 1
                    ? y + (rowHeight - cloneHeight) / 2
                    : y + rowHeight - cloneHeight
                window.targetWidth = cloneWidth
                window.targetHeight = cloneHeight
                x += cellWidth + spacing
            }
            y += rowHeight + spacing
        }
      }
    }
    return captures
}
