const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8').replace(/^\uFEFF/, '');
const manifest = JSON.parse(read('data-sources/manifest.json'));
const check = process.argv.includes('--check');
const common = [171,164,333,202,182,165,186,393,197,185,356,129];
const configs = Object.values(JSON.parse(read('config/clients.json')));
assert.equal(manifest.schema, 1);
assert.equal(manifest.clients.length, 3);
assert.equal(new Set(manifest.clients.map(c=>c.flavor)).size, 3);
function csv(text) {
  // Forever adds localized text columns. Parse quoted CSV without evaluating source code.
  const records = []; let record = [], cell = '', quoted = false;
  text = text.replace(/^\uFEFF/, '');
  for (let i=0; i<text.length; i++) {
    const c = text[i];
    if (c === '"') {
      if (quoted && text[i+1] === '"') { cell += '"'; i++; }
      else quoted = !quoted;
    } else if (!quoted && (c === ',' || c === '\n')) {
      record.push(cell.replace(/\r$/, '')); cell = '';
      if (c === '\n') { records.push(record); record = []; }
    } else cell += c;
  }
  assert(!quoted, 'Unterminated CSV quote');
  if (cell || record.length) { record.push(cell.replace(/\r$/, '')); records.push(record); }
  const fields = records.shift();
  assert.equal(new Set(fields).size, fields.length);
  return { fields, rows: records.map(cells => {
    assert.equal(cells.length, fields.length, 'CSV column count');
    return Object.fromEntries(fields.map((key, i) => [key, /^-?\d+$/.test(cells[i]) ? Number(cells[i]) : cells[i]]));
  }) };
}
function output(file, text) {
  if (check) assert.equal(read(file), text, `${file}: generated output is stale`);
  else { fs.mkdirSync(path.dirname(path.join(root, file)), { recursive:true }); fs.writeFileSync(path.join(root, file), text); }
}
const reports = [];
for (const client of manifest.clients) {
  assert(['era','titan','forever'].includes(client.flavor));
  const config = configs.find(c=>c.flavor===client.flavor);
  assert.equal(client.build, config.observedVersion, 'Source build differs from target client; fetch again');
  assert.equal(client.interface, config.interface);
  assert.equal(client.files.length, 2);
  assert.equal(new Set(client.files.map(f=>f.table)).size, 2);
  const tables = {};
  for (const file of client.files) {
    assert.equal(file.path, `wago/${client.flavor}/${file.table}.csv`);
    const buffer = fs.readFileSync(path.join(root, 'data-sources', file.path));
    assert.equal(crypto.createHash('sha256').update(buffer).digest('hex'), file.sha256, file.path);
    tables[file.table] = csv(buffer.toString('utf8'));
  }
  const allowed = new Set([...common, ...(client.flavor === 'titan' ? [755,773] : [])]);
  for (const field of ['SkillLine','Spell']) assert(tables.SkillLineAbility.fields.includes(field));
  for (const field of ['SpellID', ...Array.from({length:8},(_,i)=>`Reagent_${i}`), ...Array.from({length:8},(_,i)=>`ReagentCount_${i}`)]) assert(tables.SpellReagents.fields.includes(field));
  const bySpell = new Map();
  for (const row of tables.SpellReagents.rows) {
    assert(Number.isInteger(row.SpellID) && row.SpellID > 0);
    assert(!bySpell.has(row.SpellID), `duplicate reagent spell ${row.SpellID}`);
    const reagents = {};
    for (let i=0; i<8; i++) if (row[`Reagent_${i}`] > 0 && row[`ReagentCount_${i}`] > 0) {
      assert(Number.isInteger(row[`Reagent_${i}`]) && Number.isInteger(row[`ReagentCount_${i}`]));
      reagents[row[`Reagent_${i}`]] = row[`ReagentCount_${i}`];
    }
    bySpell.set(row.SpellID, reagents);
  }
  const recipes = new Map(), rules = new Map();
  for (const row of tables.SkillLineAbility.rows) {
    assert(Number.isInteger(row.SkillLine) && Number.isInteger(row.Spell));
    if (!allowed.has(row.SkillLine)) continue;
    const reagents = bySpell.get(row.Spell);
    if (!reagents || !Object.keys(reagents).length) continue;
    const key = `${row.SkillLine}:${row.Spell}`;
    recipes.set(key, { professionID:row.SkillLine, spellID:row.Spell, reagents });
    for (const item of Object.keys(reagents).map(Number)) {
      if (!rules.has(item)) rules.set(item, new Set());
      rules.get(item).add(row.SkillLine);
    }
  }
  const sorted = [...rules].sort((a,b) => a[0]-b[0]);
  assert(recipes.size > 1000 && rules.size > 300, 'Unexpectedly small dataset');
  const report = { flavor:client.flavor, build:client.build, retrievedAt:client.retrievedAt,
    recipeRelations:recipes.size, materials:rules.size,
    professionRelations:sorted.reduce((sum,[,values]) => sum+values.size,0),
    professions:[...allowed].sort((a,b)=>a-b).map(id => ({id, recipes:[...recipes.values()].filter(r=>r.professionID===id).length})),
    limitations:['Client spell records may include unavailable recipes; no live availability filter.',
      'Generic milling/prospecting inputs and non-recipe supplies require curated supplements.'] };
  reports.push(report);
  output(`data-sources/normalized/${client.flavor}.json`, JSON.stringify({ ...report,
    recipes:[...recipes.values()].sort((a,b)=>a.professionID-b.professionID || a.spellID-b.spellID) }, null, 2)+'\n');
  const lua = ['-- Generated by scripts/data/build.cjs; do not edit.',
    `-- Source: wago.tools, client ${client.build}; retrieved ${client.retrievedAt}.`,
    'local _, ns = ...', `if ns.Compatibility.Flavor() ~= "${client.flavor}" then return end`,
    `ns.MaterialData.Load("${client.flavor}", "${client.build}", {`];
  for (const [id, values] of sorted) lua.push(`    [${id}] = {${[...values].sort((a,b)=>a-b).join(',')}},`);
  lua.push('})', '');
  output(`Data/Generated/${client.flavor}.lua`, lua.join('\n'));
}
output('data-sources/coverage.json', JSON.stringify(reports,null,2)+'\n');
for (const report of reports) console.log(`${report.flavor} ${report.build}: ${report.recipeRelations} recipe relations, ${report.materials} items, ${report.professionRelations} item/profession links`);
