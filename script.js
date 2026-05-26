/* =============================================
   PATRICK ISOLOKWU — Portfolio Script
   Premium Interactions & Animations
   ============================================= */

/* ---- 1. SCROLL PROGRESS BAR ---- */
window.addEventListener('scroll', () => {
  const scrollTop    = document.documentElement.scrollTop;
  const scrollTotal  = document.documentElement.scrollHeight - document.documentElement.clientHeight;
  const pct          = (scrollTop / scrollTotal) * 100;
  const bar          = document.getElementById('scrollProgress');
  if (bar) bar.style.width = pct + '%';
});

/* ---- 2. STICKY HEADER ---- */
const header = document.getElementById('header');
window.addEventListener('scroll', () => {
  if (!header) return;
  if (window.scrollY > 60) header.classList.add('scrolled');
  else                      header.classList.remove('scrolled');
});

/* ---- 3. HAMBURGER MENU ---- */
const hamburger = document.getElementById('hamburger');
const navLinks  = document.getElementById('navLinks');
if (hamburger && navLinks) {
  hamburger.addEventListener('click', () => {
    hamburger.classList.toggle('active');
    navLinks.classList.toggle('open');
  });
  // Close on link click
  navLinks.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', () => {
      hamburger.classList.remove('active');
      navLinks.classList.remove('open');
    });
  });
}

/* ---- 4. SMOOTH SCROLL ---- */
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function(e) {
    const target = document.querySelector(this.getAttribute('href'));
    if (!target) return;
    e.preventDefault();
    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });
});

/* ---- 5. ACTIVE NAV LINK (Intersection Observer) ---- */
const sections = document.querySelectorAll('section[id]');
const navItems = document.querySelectorAll('.nav-link[data-section]');

const sectionObserver = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      navItems.forEach(n => n.classList.remove('active'));
      const active = document.querySelector(`.nav-link[data-section="${entry.target.id}"]`);
      if (active) active.classList.add('active');
    }
  });
}, { threshold: 0.4 });

sections.forEach(s => sectionObserver.observe(s));

/* ---- 6. REVEAL ON SCROLL ---- */
const revealObserver = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('in-view');
      revealObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.12, rootMargin: '0px 0px -60px 0px' });

document.querySelectorAll('.reveal, .reveal-left, .reveal-right, .timeline-item').forEach(el => {
  revealObserver.observe(el);
});

/* ---- 7. ANIMATED COUNTER ---- */
function animateCounter(el, target, prefix = '', suffix = '', duration = 2000) {
  const isLarge   = target >= 1e8;
  const start     = 0;
  const startTime = performance.now();

  function update(now) {
    const elapsed = now - startTime;
    const progress = Math.min(elapsed / duration, 1);
    // Ease-out-expo
    const eased = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
    const current = Math.floor(eased * target);

    let display;
    if (target >= 1e9)        display = (current / 1e9).toFixed(1) + 'B';
    else if (target >= 1e6)   display = (current / 1e6).toFixed(1) + 'M';
    else                      display = current.toLocaleString();

    el.textContent = prefix + display + suffix;
    if (progress < 1) requestAnimationFrame(update);
  }
  requestAnimationFrame(update);
}

const metricCards = document.querySelectorAll('.metric-card');
const counterObserver = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const card   = entry.target;
      const el     = card.querySelector('.metric-number');
      const target = parseInt(card.dataset.count, 10);
      const prefix = card.dataset.prefix || '';
      const suffix = card.dataset.suffix || '';
      if (el && target) animateCounter(el, target, prefix, suffix);
      counterObserver.unobserve(card);
    }
  });
}, { threshold: 0.4 });

metricCards.forEach(c => counterObserver.observe(c));

/* ---- 8. SKILL BAR ANIMATION ---- */
const skillFills = document.querySelectorAll('.skill-fill');
const skillObserver = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const fill  = entry.target;
      const width = fill.dataset.width + '%';
      setTimeout(() => { fill.style.width = width; }, 200);
      skillObserver.unobserve(fill);
    }
  });
}, { threshold: 0.3 });

skillFills.forEach(f => skillObserver.observe(f));

/* ---- 9. DATA FLOW NODE ANIMATION ---- */
const flowNodes = document.querySelectorAll('.flow-node');
let flowIndex = 0;

function cycleFlowNodes() {
  flowNodes.forEach(n => n.classList.remove('active'));
  if (flowNodes[flowIndex]) flowNodes[flowIndex].classList.add('active');
  flowIndex = (flowIndex + 1) % flowNodes.length;
}

const flowSection = document.getElementById('metrics');
if (flowSection) {
  const flowObserver = new IntersectionObserver(entries => {
    if (entries[0].isIntersecting) {
      cycleFlowNodes();
      setInterval(cycleFlowNodes, 900);
      flowObserver.disconnect();
    }
  }, { threshold: 0.3 });
  flowObserver.observe(flowSection);
}

/* ---- 10. PARTICLE CANVAS ---- */
const canvas  = document.getElementById('particle-canvas');
const ctx     = canvas ? canvas.getContext('2d') : null;
let particles = [];
let animId;

function resizeCanvas() {
  if (!canvas) return;
  canvas.width  = window.innerWidth;
  canvas.height = window.innerHeight;
}

function createParticles() {
  particles = [];
  const count = Math.floor((window.innerWidth * window.innerHeight) / 18000);
  for (let i = 0; i < count; i++) {
    particles.push({
      x:   Math.random() * canvas.width,
      y:   Math.random() * canvas.height,
      vx:  (Math.random() - 0.5) * 0.4,
      vy:  (Math.random() - 0.5) * 0.4,
      r:   Math.random() * 1.5 + 0.5,
      alpha: Math.random() * 0.5 + 0.1
    });
  }
}

function drawParticles() {
  if (!ctx) return;
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  // Draw connections
  for (let i = 0; i < particles.length; i++) {
    for (let j = i + 1; j < particles.length; j++) {
      const dx   = particles[i].x - particles[j].x;
      const dy   = particles[i].y - particles[j].y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < 120) {
        ctx.beginPath();
        ctx.strokeStyle = `rgba(0,212,255,${0.08 * (1 - dist / 120)})`;
        ctx.lineWidth   = 0.5;
        ctx.moveTo(particles[i].x, particles[i].y);
        ctx.lineTo(particles[j].x, particles[j].y);
        ctx.stroke();
      }
    }
  }

  // Draw dots
  particles.forEach(p => {
    ctx.beginPath();
    ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
    ctx.fillStyle = `rgba(0,212,255,${p.alpha})`;
    ctx.fill();

    p.x += p.vx;
    p.y += p.vy;
    if (p.x < 0 || p.x > canvas.width)  p.vx *= -1;
    if (p.y < 0 || p.y > canvas.height) p.vy *= -1;
  });

  animId = requestAnimationFrame(drawParticles);
}

if (canvas) {
  resizeCanvas();
  createParticles();
  drawParticles();
  window.addEventListener('resize', () => {
    resizeCanvas();
    createParticles();
  });
}

/* ---- 11. PROJECT CARD HOVER TILT ---- */
document.querySelectorAll('.project-card').forEach(card => {
  card.addEventListener('mousemove', e => {
    const rect   = card.getBoundingClientRect();
    const x      = ((e.clientX - rect.left) / rect.width  - 0.5) * 10;
    const y      = ((e.clientY - rect.top)  / rect.height - 0.5) * 10;
    card.style.transform = `perspective(800px) rotateY(${x}deg) rotateX(${-y}deg) translateY(-6px)`;
  });
  card.addEventListener('mouseleave', () => {
    card.style.transform = '';
  });
});

/* ---- 12. METRIC CARD GLOW ON HOVER ---- */
document.querySelectorAll('.metric-card').forEach(card => {
  card.addEventListener('mousemove', e => {
    const rect = card.getBoundingClientRect();
    const x    = e.clientX - rect.left;
    const y    = e.clientY - rect.top;
    card.style.background = `radial-gradient(circle at ${x}px ${y}px, rgba(0,212,255,0.07) 0%, var(--bg-card) 60%)`;
  });
  card.addEventListener('mouseleave', () => {
    card.style.background = '';
  });
});

/* ---- 13. CONTACT FORM FEEDBACK ---- */
const form = document.getElementById('contactForm');
if (form) {
  form.addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn    = document.getElementById('sendMsgBtn');
    const orig   = btn.innerHTML;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending…';
    btn.disabled  = true;

    try {
      const res = await fetch(form.action, {
        method:  'POST',
        body:    new FormData(form),
        headers: { 'Accept': 'application/json' }
      });
      if (res.ok) {
        btn.innerHTML = '<i class="fas fa-check-circle"></i> Message Sent!';
        btn.style.background = 'linear-gradient(135deg,#10b981,#059669)';
        form.reset();
        setTimeout(() => {
          btn.innerHTML = orig;
          btn.style.background = '';
          btn.disabled  = false;
        }, 4000);
      } else {
        throw new Error('Server error');
      }
    } catch {
      btn.innerHTML = '<i class="fas fa-exclamation-circle"></i> Try again';
      btn.style.background = 'linear-gradient(135deg,#ef4444,#dc2626)';
      setTimeout(() => {
        btn.innerHTML = orig;
        btn.style.background = '';
        btn.disabled  = false;
      }, 3000);
    }
  });
}

/* ---- 14. CURSOR SPOTLIGHT (desktop only) ---- */
if (window.matchMedia('(min-width:1024px)').matches) {
  document.addEventListener('mousemove', e => {
    const x = (e.clientX / window.innerWidth)  * 100;
    const y = (e.clientY / window.innerHeight) * 100;
    document.body.style.setProperty('--mx', x + '%');
    document.body.style.setProperty('--my', y + '%');
  });
}

/* ---- 15. TYPING EFFECT on hero subtitle (optional enhancement) ---- */
// Already handled by CSS animations; no extra JS needed.

console.log('%c Patrick Isolokwu — Data & Business Analyst Portfolio', 'color:#00d4ff; font-size:14px; font-weight:bold;');
console.log('%c Built with precision. Driven by data.', 'color:#7c3aed; font-size:12px;');