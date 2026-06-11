export const profile = {
  name: 'Syed Farhan',
  role: 'Full Stack Developer',
  tagline: 'I turn ideas into fast, scalable web applications.',
  about: [
    `I'm a full stack developer from Hyderabad, India, specializing in the MERN stack — MongoDB, Express, React and Node.js. I love working at the intersection of design, technology and innovation, transforming concepts into high-performance applications that balance great user experience with clean, maintainable code.`,
    `From RESTful APIs and serverless backends on AWS to real-time apps with WebSockets and AI-powered tools, I enjoy shipping products end to end. I'm a self-driven learner who picks up new technologies fast — recently diving deeper into TypeScript, NestJS and serverless architecture.`,
  ],
  location: 'Hyderabad, India',
  email: 'syedfarhan596@gmail.com',
  socials: {
    github: 'https://github.com/syedfarhan-596',
    linkedin: 'https://www.linkedin.com/in/syedfarhan596/',
    twitter: 'https://x.com/syedfarhan596',
  },
  resume: '/Syed_Farhan_Resume.pdf',
  stats: [
    { value: '2+', label: 'Years building for the web' },
    { value: '15+', label: 'Projects shipped' },
    { value: '10+', label: 'Technologies mastered' },
  ],
}

export const experience = [
  {
    company: 'FreshBus',
    role: 'Software Development Engineer',
    period: 'Sep 2024 — Present',
    location: 'Hyderabad, India',
    points: [
      'Building the customer-facing bus booking platform — search, seat selection and booking flows used by travelers every day.',
      'Developing internal operations dashboards for routes, fleet and booking management, reducing manual ops work.',
      'Designing and shipping backend REST APIs and integrations with Node.js and TypeScript.',
      'Owning deployments and cloud infrastructure on AWS, including serverless services.',
    ],
    tech: ['React', 'TypeScript', 'Node.js', 'AWS', 'Serverless'],
  },
  {
    company: 'SyllogisticsAI',
    role: 'MERN Stack Intern',
    period: 'Nov 2023 — May 2024',
    location: 'Hyderabad, India',
    points: [
      'Developed full-stack applications using MongoDB, Express, React and Node.js, contributing to scalable, efficient web products.',
      'Implemented RESTful APIs and integrated third-party services, strengthening backend development and API integration skills.',
      'Collaborated with a team of developers following software engineering best practices — version control, reviews and sprint planning.',
    ],
    tech: ['MongoDB', 'Express', 'React', 'Node.js', 'REST APIs'],
  },
]

export const projects = [
  {
    title: 'SRYTAL Resource Management',
    description:
      'A resource management platform for teams — employee onboarding, resource allocation and tracking workflows, built with a type-safe React frontend and deployed on Vercel.',
    tech: ['React', 'TypeScript', 'Node.js', 'Vercel'],
    live: 'https://srytal-client.vercel.app',
    repo: 'https://github.com/syedfarhan-596/SRYTAL-FE',
    accent: '#2dd4bf',
    icon: 'platform',
  },
  {
    title: 'Code For Digital India',
    description:
      'A comprehensive internship management platform with user and admin dashboards — registration, OTP-verified onboarding, resume uploads to AWS S3, task assignment and status tracking.',
    tech: ['React', 'Node.js', 'MongoDB', 'Express', 'AWS S3', 'Mantine'],
    live: 'https://codefordigitalindia-syed.netlify.app/',
    repo: 'https://github.com/syedfarhan-596',
    accent: '#7c5cff',
    icon: 'platform',
  },
  {
    title: 'JobHunt',
    description:
      'A job portal web application with job and company browsing, smart filtering, pagination and application tracking. JWT authentication with a polished Material UI interface.',
    tech: ['React', 'Node.js', 'Express', 'MongoDB', 'JWT', 'Material UI'],
    repo: 'https://github.com/syedfarhan-596',
    accent: '#22d3ee',
    icon: 'search',
  },
  {
    title: 'ASK-PDF',
    description:
      'An AI-powered tool that lets you chat with your documents — upload any PDF and ask questions in natural language to get instant, context-aware answers.',
    tech: ['Python', 'LangChain', 'LLMs', 'Embeddings'],
    repo: 'https://github.com/syedfarhan-596/ASK-PDF',
    accent: '#f472b6',
    icon: 'ai',
  },
  {
    title: 'Serverless NestJS API',
    description:
      'A production-style serverless backend built with NestJS and deployed on AWS Lambda — typed, modular architecture with zero idle cost and instant scale.',
    tech: ['NestJS', 'TypeScript', 'AWS Lambda', 'Serverless'],
    repo: 'https://github.com/syedfarhan-596/Serverless-NestJs-Lambda',
    accent: '#fb923c',
    icon: 'cloud',
  },
  {
    title: 'E-Commerce Store',
    description:
      'A full MERN e-commerce experience — product listings, search, shopping cart, user accounts and order processing for a seamless end-to-end shopping flow.',
    tech: ['React', 'Node.js', 'MongoDB', 'Express'],
    repo: 'https://github.com/syedfarhan-596',
    accent: '#34d399',
    icon: 'cart',
  },
  {
    title: 'Live Score — WebSockets',
    description:
      'A real-time score tracking app built to master WebSockets — instant bidirectional updates pushed to every connected client with zero polling.',
    tech: ['TypeScript', 'WebSockets', 'Node.js'],
    repo: 'https://github.com/syedfarhan-596/Web-Sockets-Score-App',
    accent: '#facc15',
    icon: 'bolt',
  },
  {
    title: 'AutoFill Extension',
    description:
      'A browser extension that intelligently auto-fills forms — saving repetitive typing with configurable field profiles, built on the Chrome Extensions API.',
    tech: ['JavaScript', 'Chrome APIs', 'DOM'],
    repo: 'https://github.com/syedfarhan-596/Autofull-Extension',
    accent: '#60a5fa',
    icon: 'wand',
  },
  {
    title: 'AudioMix',
    description:
      'Backend APIs for a music application built with Django REST Framework — track management, playlists and streaming-ready endpoints.',
    tech: ['Python', 'Django', 'DRF', 'SQL'],
    repo: 'https://github.com/syedfarhan-596/audiomix',
    accent: '#a78bfa',
    icon: 'music',
  },
]

export const skills = [
  {
    group: 'Languages',
    items: ['JavaScript', 'TypeScript', 'Python', 'SQL', 'HTML', 'CSS'],
  },
  {
    group: 'Frontend',
    items: ['React', 'Next.js', 'Redux / Recoil', 'Tailwind CSS', 'Material UI', 'Mantine', 'React Hook Form', 'Zod'],
  },
  {
    group: 'Backend',
    items: ['Node.js', 'Express', 'NestJS', 'Django', 'REST APIs', 'WebSockets', 'JWT Auth', 'Mongoose'],
  },
  {
    group: 'Database & Cloud',
    items: ['MongoDB', 'AWS S3', 'AWS Lambda', 'Serverless', 'Render', 'Netlify', 'Vercel'],
  },
  {
    group: 'Tools',
    items: ['Git', 'GitHub', 'VS Code', 'Postman', 'npm'],
  },
]

export const education = [
  {
    school: 'Lords Institute of Engineering and Technology',
    degree: 'B.E. in Information Technology',
    period: 'Graduated Jun 2024',
    location: 'Hyderabad',
  },
  {
    school: 'TKR College of Engineering and Technology',
    degree: 'Diploma in Computer Science',
    period: 'Completed Aug 2021',
    location: 'Hyderabad',
  },
]
