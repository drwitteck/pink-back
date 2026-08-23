const fs = require('fs'), vm = require('vm');

// ---- minimal DOM stub -------------------------------------------------
const store = {};
function mkEl(id) {
  return {
    id, value: '', _html: '', style: {}, files: [],
    get innerHTML() { return this._html; },
    set innerHTML(v) { this._html = String(v); },
    classList: { _s: new Set(), add(c){this._s.add(c)}, remove(c){this._s.delete(c)},
                 toggle(c,f){f?this._s.add(c):this._s.delete(c)}, contains(c){return this._s.has(c)} },
    addEventListener(){}, insertAdjacentHTML(pos, h){ this._html += h; },
    appendChild(){}, remove(){}, click(){}, dataset:{}
  };
}
const els = {};
// Editor form fields only exist while the sheet is drawn. Returning null unless a test
// explicitly seeds one mirrors the real DOM and keeps syncFields() honest.
const FORM = new Set(['fWeight', 'fNotes', 'fDate', 'fDose']);
const document = {
  getElementById: id => FORM.has(id) ? (els[id] || null) : (els[id] ||= mkEl(id)),
  querySelectorAll: () => [],
  createElement: () => mkEl('tmp'),
  body: { style: {}, appendChild(){}, removeChild(){} },
};
const localStorage = {
  getItem: k => (k in store ? store[k] : null),
  setItem: (k, v) => { store[k] = String(v); },
};
const sessionStorage = { getItem: () => null, setItem: () => {} };
const ctx = {
  document, localStorage, sessionStorage, console,
  navigator: { standalone: false },
  matchMedia: () => ({ matches: false }),
  location: { protocol: 'http:', hostname: '127.0.0.1' },
  setTimeout, clearTimeout, scrollTo(){}, confirm: () => true,
  Blob: class { constructor(p){ this.parts = p; } },
  File: class { constructor(p, n, o){ this.parts = p; this.name = n; Object.assign(this, o); } },
  URL: { createObjectURL: () => 'blob:x', revokeObjectURL(){} },
  Date, Math, JSON, Number, Object, Array, String, parseFloat, parseInt, isFinite,
};
ctx.window = ctx; ctx.globalThis = ctx;
vm.createContext(ctx);

// ---- load the app's real script blocks --------------------------------
const html = fs.readFileSync(require('path').join(__dirname, 'index.html'), 'utf8');
for (const m of html.matchAll(/<script>([\s\S]*?)<\/script>/g)) {
  vm.runInContext(m[1], ctx);
}

// ---- assertions -------------------------------------------------------
let pass = 0, fail = 0;
const ok = (name, cond, extra='') => cond
  ? (pass++, console.log('  ok   ' + name))
  : (fail++, console.log('  FAIL ' + name + (extra ? '  → ' + extra : '')));

const g = n => vm.runInContext(n, ctx);
const run = code => vm.runInContext(code, ctx);

// 1. boot
ok('boots with empty state', g('state.entries').length === 0);
ok('defaults to pounds', g('state.unit') === 'lb');

// 2. unit round trip
run("state.unit='lb'");
const rt = run('toKg(200)');
ok('lb→kg→lb round trip', Math.abs(run(`fromKg(${rt})`) - 200) < 1e-9, rt);
ok('kg stored canonically', Math.abs(rt - 90.718474) < 1e-4, rt);

// 3. create entries through the real editor flow
run(`openEditor()`);
run(`draft.weightText='210.5'; draft.feeling=2; draft.se=[{k:'Nausea',s:2}]; draft.notes='rough day'; draft.date='2026-06-01'; draft.shot=true; draft.dose=5;`);
run(`saveDraft()`);
run(`openEditor()`);
run(`draft.weightText='198.0'; draft.feeling=4; draft.date='2026-08-01';`);
run(`saveDraft()`);
run(`openEditor()`);
run(`draft.weightText='191.2'; draft.feeling=5; draft.se=[{k:'Fatigue',s:1}]; draft.date='2026-08-20';`);
run(`saveDraft()`);
ok('three entries saved', g('state.entries').length === 3);
ok('newest first', g('state.entries')[0].date === '2026-08-20');
ok('weight stored as kg', Math.abs(g('state.entries')[0].weightKg - 191.2/2.2046226218) < 1e-6);
ok('dose kept on injection day', g('state.entries')[2].dose === 5);

// 3b. syncFields must lift typed values off the DOM
els['fWeight'] = mkEl('fWeight'); els['fWeight'].value = '188.4';
els['fNotes']  = mkEl('fNotes');  els['fNotes'].value  = 'typed into the box';
els['fDate']   = mkEl('fDate');   els['fDate'].value   = '2026-08-21';
run(`openEditor(); syncFields(); saveDraft();`);
delete els['fWeight']; delete els['fNotes']; delete els['fDate'];
const typed = g('state.entries').find(e => e.date === '2026-08-21');
ok('syncFields reads typed weight', typed && Math.abs(typed.weightKg - 188.4/2.2046226218) < 1e-6);
ok('syncFields reads typed notes', typed && typed.notes === 'typed into the box');
run(`state.entries = state.entries.filter(e => e.date !== '2026-08-21'); save();`);

// 4. persistence round trip
ok('persisted to localStorage', !!store['zeptracker.v1']);
run(`state = {v:1,unit:'lb',lastBackup:null,entries:[]}; load();`);
ok('reload restores entries', g('state.entries').length === 3);
ok('reload preserves weight', Math.abs(g('state.entries')[0].weightKg - 191.2/2.2046226218) < 1e-6);

// 5. unit switch must not mutate data
const before = g('state.entries')[0].weightKg;
run("state.unit='kg'; render();");
ok('switching units leaves data untouched', g('state.entries')[0].weightKg === before);
ok('kg display formats', run('fmtW(state.entries[0].weightKg)') === '86.7 kg', run('fmtW(state.entries[0].weightKg)'));
run("state.unit='lb'; render();");
ok('lb display formats', run('fmtW(state.entries[0].weightKg)') === '191.2 lb', run('fmtW(state.entries[0].weightKg)'));

// 6. charts produce clean geometry
run('range = 0');
run('renderTrends()');
const trends = els['trends'].innerHTML;
ok('trends renders', trends.length > 200);
ok('no NaN in chart output', !/NaN|Infinity|undefined/.test(trends),
   (trends.match(/NaN|Infinity|undefined/g) || []).slice(0,3).join(','));
ok('weight change shown as loss', /−|-19\.3 lb/.test(trends) || trends.includes('-19.3 lb'), 'change tile');
ok('side effect bars present', trends.includes('Nausea') && trends.includes('Fatigue'));

// single weigh-in must not blow up the chart scale
run(`state.entries = [state.entries[0]]; renderTrends();`);
ok('single entry does not break trends', !/NaN/.test(els['trends'].innerHTML));
run(`load(); render();`);

// 7. views render without throwing
let threw = null;
try { run('renderToday(); renderHistory(); renderSettings(); renderTrends();'); }
catch (e) { threw = e.message; }
ok('all views render', threw === null, threw);
ok('history groups by month', els['history'].innerHTML.includes('August 2026') && els['history'].innerHTML.includes('June 2026'));

// 8. banner must not stack across renders
run('renderToday();');
const one = (els['banner'].innerHTML.match(/accent-soft/g) || []).length;
run('renderToday(); renderToday(); renderToday();');
const many = (els['banner'].innerHTML.match(/accent-soft/g) || []).length;
ok('A2HS banner does not stack across renders', one === 1 && many === 1, `1 render=${one}, 4 renders=${many}`);
ctx.navigator.standalone = true;
run('renderToday();');
ok('banner hidden once installed to Home Screen', els['banner'].innerHTML === '');
ctx.navigator.standalone = false;

// 9. CSV
let captured = null;
run(`download = (n,t,m) => { captured = {n,t,m}; };`);
ctx.captured = null;
run(`exportCSV()`);
const csv = ctx.captured ? ctx.captured.t : run('captured && captured.t');
ok('CSV exported', typeof csv === 'string' && csv.length > 0);
if (typeof csv === 'string') {
  const lines = csv.trim().split('\n');
  ok('CSV header is stable', lines[0] === 'date,weight_lb,feeling,feeling_label,injection,dose_mg,side_effects,notes', lines[0]);
  ok('CSV row count', lines.length === 4, lines.length);
  ok('CSV oldest first', lines[1].startsWith('2026-06-01'), lines[1]);
  ok('CSV severity labelled', lines[1].includes('Nausea (Moderate)'), lines[1]);
  ok('CSV quotes commas', !lines.some(l => l.split(',').length > 8 && !l.includes('"')));
}

// 10. commas/quotes in notes survive
run(`openEditor(); draft.date='2026-08-22'; draft.notes='ate, then "napped"'; draft.weightText=''; saveDraft();`);
ctx.captured = null; run(`exportCSV()`);
const csv2 = run('captured.t');
ok('CSV escapes quotes and commas', csv2.includes('"ate, then ""napped"""'), csv2.split('\n').pop());
ok('blank weight allowed', g('state.entries').find(e => e.date === '2026-08-22').weightKg === null);

console.log(`\n  ${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
