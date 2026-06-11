# Syed Farhan — 3D Portfolio

A 3D interactive portfolio built with **React + Three.js** (react-three-fiber), featuring an animated particle field, a morphing 3D orb with orbit rings, mouse-parallax, 3D tilt cards, scroll reveals and a glassmorphism dark UI.

## Run locally

```bash
npm install
npm run dev      # http://localhost:5173
```

## Build for production

```bash
npm run build    # outputs to dist/
npm run preview  # preview the production build
```

## Deploy

The `dist/` folder is a static site — deploy it anywhere:

- **Netlify / Vercel**: connect the repo, build command `npm run build`, output dir `dist`
- **GitHub Pages**: push `dist/` or use an action; set `base` in `vite.config.js` if hosted under a sub-path

## Customize

- All content (bio, experience, projects, skills, education, links) lives in [`src/data.js`](src/data.js)
- The resume served by the "Download Resume" buttons is [`public/Syed_Farhan_Resume.pdf`](public/Syed_Farhan_Resume.pdf) — replace that file to update it
- Profile photo: `public/syed.jpg`
- 3D scene (particles, orb, lighting): [`src/components/Scene3D.jsx`](src/components/Scene3D.jsx)
- Theme colors: CSS variables at the top of [`src/index.css`](src/index.css)

## Performance notes

- The three.js scene is lazy-loaded so first paint is instant
- Particle count and pixel ratio are reduced on mobile
- Honors `prefers-reduced-motion` (animations and the render loop are disabled)
- Single fixed canvas shared across the page; the hero orb fades out on scroll
