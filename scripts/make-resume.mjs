/* Renders scripts/resume.html to public/Syed_Farhan_Resume.pdf via headless Edge */
import puppeteer from 'puppeteer-core'
import fs from 'node:fs'
import path from 'node:path'

const EDGE = [
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
].find((p) => fs.existsSync(p))

const browser = await puppeteer.launch({ executablePath: EDGE, headless: 'new' })
const page = await browser.newPage()
await page.goto('file://' + path.resolve('scripts/resume.html'), { waitUntil: 'networkidle0' })
await page.pdf({
  path: 'public/Syed_Farhan_Resume.pdf',
  format: 'A4',
  printBackground: true,
  margin: { top: 0, bottom: 0, left: 0, right: 0 },
})
await browser.close()
console.log('public/Syed_Farhan_Resume.pdf written')
