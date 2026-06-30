---
name: Admin console design system
description: Premium glassmorphism CSS classes and design tokens for the HeartSync admin console
---

All design tokens and component classes are in `client/src/index.css`.

**Key CSS classes:**
- `.glass-card` — glass card with blur(12px), border `rgba(255,255,255,0.08)`, hover: translateY(-5px) + rose glow
- `.stat-card` — glass stat card with ::before top-gradient reveal on hover, ambient glow orb inside
- `.nav-item` — sidebar nav link; add `.active` for gradient fill (rose→purple with rose border)
- `.btn-grad` — gradient button rose→purple with glow shadow
- `.input-glass` — glass input with focus ring rgba(224,92,126,0.12)
- `.grad-text` — rose→purple gradient text (uses -webkit-background-clip)
- `.sidebar-glass` — sidebar backdrop-filter blur(24px) dark glass
- `.logo-orb` — gradient rose→purple logo with pulse-orb animation
- `.header-glass` — header with backdrop-filter blur(20px)
- `.anim-slide-up` + `.anim-delay-{100-500}` — staggered entrance animations
- `.section-label` — nav section divider

**Background:** Body has `radial-gradient` mesh of rose + purple + blue + green on `#07071a`.

**Why:** Components use className for animations/pseudo-elements (can't do ::before in inline styles), inline styles for dynamic color props.
