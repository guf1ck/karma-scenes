(() => {
  'use strict';
  const $ = id => document.getElementById(id);
  const editor = $('editor'), input = $('scene-text'), form = $('scene-form');
  const preview = new URLSearchParams(location.search).has('preview') && typeof GetParentResourceName !== 'function';
  const state = { open: false, busy: false, max: 198, values: {}, options: {}, dropdown: null };
  let closeTimer;
  const call = async (name, data = {}) => {
    if (preview) return { ok: true };
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    try {
      const response = await fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data), signal: controller.signal
      });
      return await response.json();
    } finally { clearTimeout(timeout); }
  };
  function resize() {
    document.documentElement.style.setProperty('--ui-scale', Math.min(1, (innerHeight - 48) / 640, (innerWidth - 32) / 426));
  }
  function count() {
    let chars = Array.from(input.value);
    if (chars.length > state.max) input.value = chars.slice(0, state.max).join('');
    $('counter').textContent = `${Array.from(input.value).length}/${state.max}`;
    $('error').hidden = true;
  }
  function closeDropdown(focus = false) {
    if (!state.dropdown) return;
    const node = $(state.dropdown + '-select');
    node.classList.remove('open');
    node.querySelector('.options').hidden = true;
    node.querySelector('.select-trigger').setAttribute('aria-expanded', 'false');
    if (focus) node.querySelector('.select-trigger').focus();
    state.dropdown = null;
  }
  function buildSelect(key, options, value) {
    const root = $(key + '-select');
    root.replaceChildren();
    root.classList.remove('open');
    state.options[key] = options;
    state.values[key] = options.some(item => item.id === value) ? value : options[0].id;
    const trigger = document.createElement('button');
    trigger.type = 'button'; trigger.className = 'select-trigger';
    trigger.setAttribute('aria-haspopup', 'listbox'); trigger.setAttribute('aria-expanded', 'false');
    trigger.setAttribute('aria-labelledby', `${key}-label ${key}-value`);
    trigger.setAttribute('aria-controls', key + '-options');
    const label = document.createElement('span'); label.id = key + '-value';
    label.textContent = options.find(item => item.id === state.values[key]).label;
    trigger.append(label);
    const chevron = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    chevron.classList.add('chevron');
    chevron.innerHTML = '<use href="#chevron"/>';
    trigger.append(chevron);
    const list = document.createElement('div'); list.className = 'options'; list.id = key + '-options';
    list.setAttribute('role', 'listbox'); list.setAttribute('aria-labelledby', key + '-label'); list.hidden = true;
    let activeIndex = 0;
    const choose = item => {
      state.values[key] = item.id; label.textContent = item.label;
      [...list.children].forEach((node, i) => node.setAttribute('aria-selected', String(options[i].id === item.id)));
      closeDropdown(true);
    };
    options.forEach(item => {
      const row = document.createElement('div'); row.className = 'option'; row.setAttribute('role', 'option');
      row.tabIndex = -1; row.setAttribute('aria-selected', String(item.id === state.values[key]));
      const text = document.createElement('span'); text.textContent = item.label; row.append(text);
      if (item.meters) { const meters = document.createElement('small'); meters.textContent = `${item.meters} m`; row.append(meters); }
      if (item.rgb) { const swatch = document.createElement('span'); swatch.className = 'swatch'; swatch.style.backgroundColor = `rgb(${item.rgb.join(',')})`; row.append(swatch); }
      row.addEventListener('click', () => choose(item));
      list.append(row);
    });
    function focusOption(index) {
      activeIndex = (index + options.length) % options.length;
      [...list.children].forEach((node, i) => node.classList.toggle('active', i === activeIndex));
      list.children[activeIndex].focus(); list.children[activeIndex].scrollIntoView({ block: 'nearest' });
    }
    function open() {
      closeDropdown(); state.dropdown = key; root.classList.add('open'); list.hidden = false;
      trigger.setAttribute('aria-expanded', 'true');
      focusOption(options.findIndex(item => item.id === state.values[key]));
    }
    trigger.addEventListener('click', () => state.dropdown === key ? closeDropdown() : open());
    // Replace the handler on reopen so it cannot select options from an old menu.
    root.onkeydown = event => {
      if (['ArrowDown', 'ArrowUp', 'Home', 'End'].includes(event.key)) {
        event.preventDefault();
        if (state.dropdown !== key) { open(); return; }
        focusOption(event.key === 'Home' ? 0 : event.key === 'End' ? options.length - 1 : activeIndex + (event.key === 'ArrowDown' ? 1 : -1));
      } else if ((event.key === 'Enter' || event.key === ' ') && state.dropdown === key) {
        event.preventDefault(); event.stopPropagation(); choose(options[activeIndex]);
      }
    };
    root.append(trigger, list);
  }
  function show(data) {
    clearTimeout(closeTimer); closeDropdown();
    state.max = data.maxLength || 198; state.open = true; state.busy = false;
    editor.hidden = false; editor.classList.remove('closing');
    $('error').hidden = true;
    form.querySelector('.submit').disabled = false;
    const values = data.draft || data.defaults;
    buildSelect('color', data.colors, values.color);
    buildSelect('size', data.sizes, values.size);
    buildSelect('distance', data.distances, values.distance);
    input.value = data.draft?.text || ''; count(); resize();
    requestAnimationFrame(() => input.focus());
  }
  function hide() {
    if (!state.open) return;
    state.open = false; closeDropdown(); input.blur();
    editor.classList.add('closing');
    closeTimer = setTimeout(() => { editor.hidden = true; editor.classList.remove('closing'); }, 180);
  }
  function error(message) { $('error').textContent = message; $('error').hidden = false; }
  async function cancel() {
    if (!state.open || state.busy) return;
    hide();
    try { await call('close'); } catch { console.error('Unable to reach the game. Press Escape again.'); }
  }
  form.addEventListener('submit', async event => {
    event.preventDefault();
    if (!state.open || state.busy || state.dropdown) return;
    if (!input.value.trim()) { error('Enter some scene text.'); input.focus(); return; }
    state.busy = true; form.querySelector('.submit').disabled = true;
    try {
      const result = await call('submit', { text: input.value, ...state.values });
      if (result.ok) hide();
      else error(result.error || 'Unable to place this scene.');
    } catch { error('Could not reach the game. Please try again.'); }
    finally { state.busy = false; form.querySelector('.submit').disabled = false; }
  });
  input.addEventListener('input', count);
  // Capture clicks before submit/close handlers hide or disable the editor.
  editor.addEventListener('click', event => {
    if (!state.open || state.busy) return;
    const control = event.target.closest('button, input, [role="option"]');
    if (!control || control.disabled) return;
    call('clickSound').catch(() => {});
  }, true);
  $('close').addEventListener('click', cancel);
  document.addEventListener('pointerdown', event => { if (!event.target.closest('.select')) closeDropdown(); });
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape') {
      event.preventDefault();
      if (state.dropdown) closeDropdown(true);
      else if (state.open) cancel();
      else if (!preview) call('close').catch(() => {});
    }
    if (event.key === 'Tab' && state.open) {
      closeDropdown();
      const focusable = [...editor.querySelectorAll('input, button:not(:disabled)')];
      const index = focusable.indexOf(document.activeElement);
      if ((event.shiftKey && index <= 0) || (!event.shiftKey && index === focusable.length - 1)) {
        event.preventDefault(); focusable[event.shiftKey ? focusable.length - 1 : 0].focus();
      }
    }
  });
  addEventListener('resize', resize);
  addEventListener('message', ({ data }) => {
    if (!data || typeof data !== 'object') return;
    if (data.action === 'open') show(data);
    if (data.action === 'close') hide();
  });
  resize();
  if (preview) {
    const options = ['small', 'medium', 'large', 'huge'].map(id => ({ id, label: id[0].toUpperCase() + id.slice(1) }));
    show({ maxLength: 198, defaults: { color: 'white', size: 'medium', distance: 'medium' },
      colors: [{ id: 'white', label: 'White', rgb: [255,255,255] }, { id: 'red', label: 'Red', rgb: [255,72,72] }, { id: 'cyan', label: 'Cyan', rgb: [49,215,239] }, { id: 'green', label: 'Green', rgb: [108,225,130] }],
      sizes: options, distances: options.map((item, i) => ({ ...item, meters: [3,8,15,25][i] })) });
  } else call('ready').catch(() => {});
})();
