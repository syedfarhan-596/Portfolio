import puppeteer from 'puppeteer-core'
import fs from 'node:fs'

const EDGE = [
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
].find((p) => fs.existsSync(p))

const browser = await puppeteer.launch({
  executablePath: EDGE,
  headless: 'new',
  args: ['--enable-unsafe-swiftshader', '--hide-scrollbars'],
})
const page = await browser.newPage()
const errors = []
page.on('console', (m) => m.type() === 'error' && errors.push(m.text()))
page.on('pageerror', (e) => errors.push(String(e)))

for (const [name, width, height] of [['q-about-desktop', 1440, 900], ['q-about-mobile', 390, 844]]) {
  await page.setViewport({ width, height, deviceScaleFactor: 1 })
  await page.goto('http://localhost:5173/#about', { waitUntil: 'networkidle0' })
  await new Promise((r) => setTimeout(r, 1500))
  await page.evaluate(() => document.querySelector('.about-photo')?.scrollIntoView({ behavior: 'instant', block: 'center' }))
  await new Promise((r) => setTimeout(r, 4000)) // let the particle assemble animation finish
  await page.screenshot({ path: `shots/${name}.png` })
  console.log(`${name} captured`)
}
console.log(errors.length ? `ERRORS:\n${errors.join('\n')}` : 'no console errors')
await browser.close()
