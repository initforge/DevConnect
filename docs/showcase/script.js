// DevConnect Showcase — Script (Direct Technical Layout)
(function() {
  'use strict';

  // ===== FILTER BUTTONS =====
  const filterBar = document.getElementById('filterBar');
  const screenGrid = document.getElementById('screenGrid');
  let activeFilter = 'all';

  Object.entries(CATEGORIES).forEach(([key, cat]) => {
    const btn = document.createElement('button');
    btn.className = `filter-btn${key === 'all' ? ' active' : ''}`;
    btn.textContent = `${cat.label} (${cat.count})`;
    btn.dataset.cat = key;
    btn.addEventListener('click', () => {
      activeFilter = key;
      filterBar.querySelectorAll('.filter-btn').forEach(b => b.classList.toggle('active', b.dataset.cat === key));
      screenGrid.querySelectorAll('.screen-card').forEach(card => {
        card.classList.toggle('hidden', key !== 'all' && card.dataset.cat !== key);
      });
    });
    filterBar.appendChild(btn);
  });

  // ===== SCREEN CARDS =====
  SCREENS.forEach(s => {
    const card = document.createElement('div');
    card.className = 'screen-card';
    card.dataset.cat = s.category;
    card.dataset.id = s.id;

    const dots = s.features.map(fId => {
      const f = FEATURES[fId];
      return f ? `<span class="dot" style="background:${f.color}" title="${f.title}"></span>` : '';
    }).join('');

    card.innerHTML = `
      <div class="screen-card-img"><img src="screenshots/${s.slug}.png" alt="${s.title}" loading="lazy"></div>
      <div class="screen-card-info">
        <div class="screen-card-title"><span class="screen-card-num">${String(s.id).padStart(2,'0')}</span>${s.title}</div>
        <div class="screen-card-meta">${s.features.length} tính năng</div>
        <div class="screen-card-dots">${dots}</div>
      </div>
    `;
    card.addEventListener('click', () => openModal(s.id - 1));
    screenGrid.appendChild(card);
  });

  // ===== FEATURES LIST (Bottom Section) =====
  const featuresFilter = document.getElementById('featuresFilter');
  const featuresList = document.getElementById('featuresList');

  const featCats = {
    all: 'Tất cả',
    security: 'Bảo mật',
    feed: 'Feed',
    social: 'Xã hội',
    data: 'Dữ liệu',
    realtime: 'Thời gian thực',
    ai: 'Trí tuệ nhân tạo',
    ui: 'Giao diện',
    tools: 'Công cụ',
    features: 'Tính năng'
  };

  Object.entries(featCats).forEach(([key, label]) => {
    const btn = document.createElement('button');
    btn.className = `filter-btn${key === 'all' ? ' active' : ''}`;
    btn.textContent = label;
    btn.dataset.cat = key;
    btn.addEventListener('click', () => {
      featuresFilter.querySelectorAll('.filter-btn').forEach(b => b.classList.toggle('active', b.dataset.cat === key));
      featuresList.querySelectorAll('.feature-item').forEach(item => {
        item.classList.toggle('hidden', key !== 'all' && item.dataset.cat !== key);
      });
    });
    featuresFilter.appendChild(btn);
  });

  Object.entries(FEATURES).forEach(([id, f]) => {
    const stars = '★'.repeat(f.difficulty) + '☆'.repeat(5 - f.difficulty);
    const item = document.createElement('div');
    item.className = 'feature-item';
    item.dataset.cat = f.category;

    item.innerHTML = `
      <button class="feature-header">
        <span class="feature-cat-dot" style="background:${f.color}"></span>
        <span class="feature-code">${f.code}</span>
        <span class="feature-name">${f.title}</span>
        <span class="feature-difficulty">${stars}</span>
        <span class="feature-time">${f.time || ''}</span>
        <svg class="feature-chevron" viewBox="0 0 16 16" fill="none"><path d="M4 6l4 4 4-4" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
      </button>
      <div class="feature-body">
        <div class="feature-content">
          <div class="feature-summary">${f.summary}</div>
          <div class="feature-details">${f.details}</div>
          <div class="feature-meta">
            <span style="color:${f.color}">${FEATURE_CATEGORIES[f.category]?.label || f.category}</span>
            ${f.time ? `<span>Est: ${f.time}</span>` : ''}
          </div>
        </div>
      </div>
    `;

    item.querySelector('.feature-header').addEventListener('click', () => {
      item.classList.toggle('open');
    });

    featuresList.appendChild(item);
  });

  // ===== MODAL =====
  let currentIndex = 0;
  let currentZoom = 1;
  const overlay = document.getElementById('modalOverlay');
  const modalImage = document.getElementById('modalImage');
  const modalTitle = document.getElementById('modalTitle');
  const modalDesc = document.getElementById('modalDesc');
  const modalPatterns = document.getElementById('modalPatterns');
  const modalFeatures = document.getElementById('modalFeatures');
  const modalCounter = document.getElementById('modalCounter');

  function openModal(index) {
    currentIndex = index;
    currentZoom = 1;
    updateModal();
    overlay.classList.add('active');
    document.body.style.overflow = 'hidden';
  }

  function closeModal() {
    overlay.classList.remove('active');
    document.body.style.overflow = '';
  }

  function updateModal() {
    const s = SCREENS[currentIndex];
    modalImage.src = `screenshots/${s.slug}.png`;
    modalImage.alt = s.title;
    modalImage.style.transform = `scale(${currentZoom})`;
    modalTitle.textContent = `${String(s.id).padStart(2,'0')}. ${s.title}`;
    modalDesc.textContent = s.description;
    modalCounter.textContent = `${s.id}/20`;

    modalPatterns.innerHTML = s.patterns.map(p =>
      `<span class="modal-pattern">${p}</span>`
    ).join('');

    modalFeatures.innerHTML = s.features.map(fId => {
      const f = FEATURES[fId];
      if (!f) return '';
      const stars = '★'.repeat(f.difficulty);
      return `
        <div class="modal-feat">
          <button class="modal-feat-header" onclick="this.parentElement.classList.toggle('open')">
            <span class="feature-cat-dot" style="background:${f.color}"></span>
            <span class="modal-feat-code">${f.code}</span>
            <span class="modal-feat-name">${f.title}</span>
            <span class="modal-feat-stars">${stars}</span>
            <svg class="modal-feat-chevron" viewBox="0 0 16 16" fill="none"><path d="M4 6l4 4 4-4" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
          </button>
          <div class="modal-feat-body">
            <div class="modal-feat-content">
              <div class="summary">${f.summary}</div>
              <div class="details">${f.details}</div>
              <div class="meta">
                <span style="color:${f.color}">${FEATURE_CATEGORIES[f.category]?.label || f.category}</span>
                ${f.time ? `<span>Est: ${f.time}</span>` : ''}
              </div>
            </div>
          </div>
        </div>
      `;
    }).join('');
  }

  // Modal controls
  document.getElementById('modalClose').addEventListener('click', closeModal);
  overlay.addEventListener('click', e => { if (e.target === overlay) closeModal(); });
  document.getElementById('modalPrev').addEventListener('click', () => {
    currentIndex = (currentIndex - 1 + SCREENS.length) % SCREENS.length;
    updateModal();
  });
  document.getElementById('modalNext').addEventListener('click', () => {
    currentIndex = (currentIndex + 1) % SCREENS.length;
    updateModal();
  });

  // Zoom
  document.getElementById('zoomIn').addEventListener('click', () => {
    currentZoom = Math.min(currentZoom + 0.25, 3);
    modalImage.style.transform = `scale(${currentZoom})`;
  });
  document.getElementById('zoomOut').addEventListener('click', () => {
    currentZoom = Math.max(currentZoom - 0.25, 0.5);
    modalImage.style.transform = `scale(${currentZoom})`;
  });
  document.getElementById('zoomReset').addEventListener('click', () => {
    currentZoom = 1;
    modalImage.style.transform = 'scale(1)';
  });

  // Keyboard
  document.addEventListener('keydown', e => {
    if (!overlay.classList.contains('active')) return;
    if (e.key === 'Escape') closeModal();
    if (e.key === 'ArrowLeft') {
      currentIndex = (currentIndex - 1 + SCREENS.length) % SCREENS.length;
      updateModal();
    }
    if (e.key === 'ArrowRight') {
      currentIndex = (currentIndex + 1) % SCREENS.length;
      updateModal();
    }
  });

  // Mouse wheel zoom
  document.querySelector('.modal-preview')?.addEventListener('wheel', e => {
    if (!overlay.classList.contains('active')) return;
    e.preventDefault();
    currentZoom = Math.max(0.5, Math.min(3, currentZoom + (e.deltaY < 0 ? 0.15 : -0.15)));
    modalImage.style.transform = `scale(${currentZoom})`;
  }, { passive: false });

})();
