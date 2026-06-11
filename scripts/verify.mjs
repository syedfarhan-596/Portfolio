/* Visual verification: drives Edge via CDP, captures desktop + mobile shots,
   checks for horizontal overflow and console errors. */
import puppeteer from 'puppeteer-core'
import fs from 'node:fs'

const EDGE = [
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
].find((p) => fs.existsSync(p))

const URL = process.env.TARGET_URL || 'http://localhost:5173'
const browser = await puppeteer.launch({
  executablePath: EDGE,
  headless: 'new',
  args: ['--enable-unsafe-swiftshader', '--hide-scrollbars'],
})

const errors = []
const page = await browser.newPage()
page.on('console', (m) => {
  if (m.type() === 'error') errors.push(m.text())
})
page.on('pageerror', (e) => errors.push(String(e)))

async function shoot(name, width, height, scrollTo) {
  await page.setViewport({ width, height, deviceScaleFactor: 1 })
  await page.goto(URL, { waitUntil: 'networkidle0' })
  await new Promise((r) => setTimeout(r, 2500)) // let the 3D scene settle
  if (scrollTo) {
    await page.evaluate((sel) => {
      document.querySelector(sel)?.scrollIntoView({ behavior: 'instant', block: 'start' })
    }, scrollTo)
    await new Promise((r) => setTimeout(r, 1200))
  }
  await page.screenshot({ path: `shots/${name}.png` })
  const overflow = await page.evaluate(() => ({
    scrollWidth: document.documentElement.scrollWidth,
    innerWidth: window.innerWidth,
    canvas: (() => {
      const c = document.querySelector('.scene3d canvas')
      return c ? `${c.width}x${c.height}` : 'MISSING'
    })(),
  }))
  console.log(
    `${name}: viewport=${width} scrollWidth=${overflow.scrollWidth} canvas=${overflow.canvas} ${overflow.scrollWidth > width ? '⚠ H-OVERFLOW' : 'ok'}`,
  )
}

await shoot('v-desktop-hero', 1440, 900)
await shoot('v-desktop-experience', 1440, 900, '#experience')
await shoot('v-desktop-projects', 1440, 900, '#projects')
await shoot('v-desktop-contact', 1440, 900, '#contact')
await shoot('v-mobile-hero', 390, 844)
await shoot('v-mobile-experience', 390, 844, '#experience')
await shoot('v-mobile-about', 390, 844, '#about')

// mobile menu open
await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 1 })
await page.goto(URL, { waitUntil: 'networkidle0' })
await new Promise((r) => setTimeout(r, 1500))
await page.click('.hamburger')
await new Promise((r) => setTimeout(r, 600))
await page.screenshot({ path: 'shots/v-mobile-menu.png' })
console.log('v-mobile-menu: captured')

// resume PDF reachable?
const res = await page.goto(`${URL}/Syed_Farhan_Resume.pdf`)
console.log(`resume pdf: HTTP ${res.status()} ${res.headers()['content-type']}`)

console.log(errors.length ? `CONSOLE ERRORS:\n${errors.join('\n')}` : 'no console errors')
await browser.close()
