export const reportHtml = `<!doctype html>
<html lang="ro"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Raport privat Slove</title></head>
<body><h1>Raport privat Slove</h1>
<p>Numai instalări cu acord pentru analiză, nu toți jucătorii. Numărul total de jucători este necunoscut. Identificatorii reprezintă instalări, nu persoane.</p>
<p>Date legate: ultimele 90 de zile. Implicit: ultimele 7 zile UTC; maximum 31 de zile per interogare. Numărătorile descriu activitatea din interval, nu neapărat întreaga rundă. Lipsa unui final nu dovedește abandonul. Nerezolvat nu înseamnă greșit. Plecarea de la un item se numără doar când apare un item următor sau finalul rundei; itemul curent fără final rămâne cu stare necunoscută. Întreruperile deduse folosesc ultima activitate estimată, nu ora exactă a închiderii aplicației.</p>
<form id="filters">
<label>De la (UTC, inclusiv) <input name="from" type="date"></label>
<label>Până la (UTC, exclusiv) <input name="to" type="date"></label>
<label>Joc <select name="game"><option value="">Toate</option><option value="grammar">Gramatică</option><option value="vocabulary">Vocabular</option><option value="idioms">Expresii</option><option value="spot">Găsește greșeala</option></select></label>
<label>Versiune conținut <input name="version" maxlength="64"></label>
<label>ID instalare anonimă <input name="installation" maxlength="128"></label>
<button>Aplică filtrele</button></form>
<p role="status" id="status"></p><section id="recent"></section><button id="next" hidden>Pagina următoare</button>
<h2>Istoric fără legături cu instalările</h2><p>Suprafață fixă: până la 52 de săptămâni UTC încheiate înaintea ultimei curățări programate finalizate, separat pe joc. Fără o curățare finalizată nu se publică nimic. Filtrele de mai sus NU se aplică. Nu sunt disponibile intervale arbitrare, zile, itemi, versiuni sau instalări. Celulele rare lipsesc; valorile sunt parțiale, nu totaluri exacte. „Suprimat / necunoscut” nu înseamnă zero. Fără procente de corectitudine comune între jocuri.</p>
<button id="history">Istoric săptămânal fix</button><section id="weeks"></section>
<script src="/private/report/app.js" defer></script></body></html>`;

export const reportScript = String.raw`
'use strict';
const form = document.getElementById('filters');
const recent = document.getElementById('recent');
const weeks = document.getElementById('weeks');
const status = document.getElementById('status');
const next = document.getElementById('next');
let cursor = null;
let sequence = 0;
const names = {grammar:'Gramatică',vocabulary:'Vocabular',idioms:'Expresii',spot:'Găsește greșeala'};
const reasons = {in_progress:'În desfășurare / final necunoscut',completed:'Finalizată',user_back:'Ieșire voluntară',restart:'Reluată',timeout:'Timp expirat',inferred_interruption:'Întrerupere dedusă — ultima activitate estimată',unknown:'Final necunoscut'};
function add(parent, tag, text) {
  const element = document.createElement(tag);
  element.textContent = text;
  parent.appendChild(element);
  return element;
}
function value(v) { return v === null || v === undefined ? 'suprimat / necunoscut' : String(v); }
function metrics(parent, m, game) {
  const common = [['started','Runde începute'],['completed','Runde finalizate'],['ended','Runde încheiate'],['inProgress','Fără final observat'],['missingStart','Început lipsă']];
  const items = [['shown',game === 'spot' ? 'Afișări de texte' : 'Exerciții afișate'],['resolved',game === 'spot' ? 'Texte rezolvate' : 'Exerciții rezolvate'],['left','Plecări fără rezolvare (item următor sau final observat)'],['openUnresolved','Fără rezolvare, fără plecare sau final observat — stare necunoscută']];
  const units = game === 'spot' ? [['attempts','Apăsări acceptate'],['discoveries','Descoperiri distincte'],['distinctWrong','Poziții greșite distincte pe rundă']] : [['correct','Răspunsuri MC corecte'],['wrong','Răspunsuri MC greșite']];
  for (const [key,label] of [...common,...items,...units]) {
    if (key in m) add(parent,'p',label + ': ' + value(m[key]));
  }
  if (game === 'spot') add(parent,'p','Apăsările includ repetările și intrările acceptate după rezolvare în versiunile vechi. Descoperirile și pozițiile greșite au unități distincte; nu sunt răspunsuri MC.');
}
async function load(history = false, following = false) {
  const requestId = ++sequence;
  status.textContent = 'Se încarcă…';
  next.hidden = true;
  recent.replaceChildren();
  weeks.replaceChildren();
  const p = new URLSearchParams();
  for (const input of form.elements) if (input.name && input.value) p.set(input.name,input.value);
  if (following && cursor) p.set('cursor',cursor);
  try {
    const response = await fetch('/private/report/api/' + (history ? 'history' : 'recent?' + p), {cache:'no-store',redirect:'error'});
    if (requestId !== sequence) return;
    if (!response.ok) {
      status.textContent = response.status === 403 ? 'Acces refuzat. Autentificați-vă din nou prin Access.' : 'Raport indisponibil. Verificați sau restrângeți filtrele.';
      return;
    }
    const data = await response.json();
    if (requestId !== sequence) return;
    status.textContent = '';
    if (history) {
      if (!data.published) add(weeks,'p','Istoric nepublicat: nicio curățare programată finalizată nu dovedește încă săptămâni închise.');
      else if (!data.weeks.length) add(weeks,'p','Nu există celule istorice publicabile.');
      for (const w of data.weeks) {
        const block = add(weeks,'article','');
        add(block,'h3', w.bucket + ' — ' + (names[w.game] || 'Joc necunoscut') + ' — valori parțiale');
        metrics(block,w,w.game);
      }
      return;
    }
    add(recent,'h2',p.has('installation') ? 'Rezumat — instalarea selectată' : 'General — numai instalări cu acord');
    for (const [game,m] of Object.entries(data.summary)) {
      const block = add(recent,'article',''); add(block,'h3',names[game] || 'Joc necunoscut'); metrics(block,m,game);
      for (const [reason,count] of Object.entries(m.endedByReason || {})) add(block,'p',(reasons[reason] || reasons.unknown) + ': ' + count);
    }
    if (!data.sessions.length) add(recent,'p','Nu există sesiuni în interval.');
    for (const s of data.sessions) {
      const block = add(recent,'article','');
      add(block,'h3',(names[s.game] || 'Joc necunoscut') + ' — ' + (reasons[s.status] || reasons.unknown));
      add(block,'p','Instalare: ' + s.installation + ' · Sesiune: ' + s.session + ' · Versiune: ' + s.version);
      const last = s.lastItem === null ? 'necunoscut în interval' : s.lastItem + ' · Index: ' + s.lastIndex +
        (s.lastItemEvidence === 'terminal' ? ' (din evenimentul final)' : ' (cel mai mare index observat în interval; finalul poate lipsi)');
      add(block,'p','Ultima activitate: ' + s.lastActivity + ' · Ultimul item: ' + last);
      if (s.missingStart) add(block,'p','Început lipsă în interval; starea inițială este necunoscută.');
      const drill = add(block,'button','Vezi această instalare');
      drill.onclick = () => {form.elements.namedItem('installation').value = s.installation; cursor = null; load();};
      metrics(block,s.metrics,s.game);
      const details = add(block,'details',''); add(details,'summary','Detalii pe item (fără text sau poziții selectate)');
      for (const item of s.items) {
        const row = add(details,'section',''); add(row,'h4','Item: ' + item.id + ' · Index în rundă: ' + item.index);
        if (item.terminalState) add(row,'p','Stare la final: ' + (item.terminalState === 'resolved' ? 'rezolvat' : 'nerezolvat (nu greșit)'));
        if (!item.shown) add(row,'p','Afișarea nu apare în interval și nu este numărată.');
        metrics(row,item,s.game);
      }
    }
    cursor = data.nextCursor;
    next.hidden = !cursor;
  } catch { if (requestId === sequence) status.textContent = 'Raport indisponibil. Reautentificați-vă sau încercați din nou.'; }
}
form.onsubmit = event => {event.preventDefault(); cursor = null; load();};
next.onclick = () => load(false,true);
document.getElementById('history').onclick = () => load(true);
load();
`;
