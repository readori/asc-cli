/* ASCBar docs — theme management */

// Apply saved theme immediately to prevent FOUC
(function () {
  var saved = localStorage.getItem('ascbar-docs-theme') || 'dark';
  document.documentElement.setAttribute('data-theme', saved);
})();

function toggleTheme() {
  var html = document.documentElement;
  var current = html.getAttribute('data-theme') || 'dark';
  var next = current === 'dark' ? 'light' : 'dark';
  html.setAttribute('data-theme', next);
  localStorage.setItem('ascbar-docs-theme', next);
  updateToggleIcon(next);
}

function updateToggleIcon(theme) {
  var btn = document.getElementById('theme-toggle-btn');
  if (!btn) return;
  var isDark = theme === 'dark';
  btn.title = isDark ? 'Switch to light mode' : 'Switch to dark mode';
  btn.innerHTML = isDark
    ? '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"/></svg>'
    : '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"/></svg>';
}

document.addEventListener('DOMContentLoaded', function () {
  updateToggleIcon(document.documentElement.getAttribute('data-theme') || 'dark');
});