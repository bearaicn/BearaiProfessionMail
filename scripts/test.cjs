const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const parser = require('luaparse');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const root = path.resolve(__dirname, '..');
const toc = fs.readFileSync(path.join(root, 'BearaiProfessionMail.toc'), 'utf8');
assert.match(toc, /## SavedVariables: BearaiProfessionMailDB/);
const files = toc.split(/\r?\n/).filter(line => line.endsWith('.lua'));
const assets = JSON.parse(fs.readFileSync(path.join(root, 'config/assets.json'), 'utf8'));
assert(assets.includes('Media/Logo.tga'));
const logo = fs.readFileSync(path.join(root, 'Media/Logo.tga'));
assert.equal(logo[2], 2);
assert.equal(logo.readUInt16LE(12), 128);
assert.equal(logo.readUInt16LE(14), 128);
assert.equal(logo[16], 32);
assert.equal(logo[17] & 15, 8);
assert.equal(logo.length, 18 + 128 * 128 * 4);
assert.equal(logo[21], 0, '外角像素应透明');
let transparent = 0, visible = 0;
for (let i = 21; i < logo.length; i += 4) { if (logo[i] === 0) transparent++; if (logo[i] > 240) visible++; }
assert(transparent > 100 && visible > 100, '纹理需同时包含透明背景和可见主体');
assert.match(toc, /## IconTexture: Interface\\AddOns\\BearaiProfessionMail\\Media\\Logo\.tga/);
for (const file of files) {
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  parser.parse(source, { luaVersion: '5.1' });
  assert.doesNotMatch(source, /\bSendMail\s*\(/, file);
  assert.doesNotMatch(source, /\bUseContainerItem\s*\(/, file);
  if (file !== 'Core/Compatibility.lua') {
    assert.doesNotMatch(source, /\bClickSendMailItemButton\s*\(/, file);
  }
}
function suite(interfaceVersion, testFiles) {
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
function run(source, name) {
  if (lauxlib.luaL_loadbuffer(L, to_luastring(source), null, to_luastring(name)) !== lua.LUA_OK ||
      lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) {
    throw new Error(`${name}: ${to_jsstring(lua.lua_tostring(L, -1))}`);
  }
}
run(fs.readFileSync(path.join(root, 'tests/mock.lua'), 'utf8'), 'mock');
run(`TEST_INTERFACE = ${interfaceVersion}`, 'client');
for (const file of files) {
  // 在同一个命名空间和 Lua 全局中按 TOC 顺序执行。
  run(`local chunk = function(...)\n${fs.readFileSync(path.join(root, file), 'utf8')}\nend\nchunk('BearaiProfessionMail', NS)`, file);
}
for (const file of testFiles) run(fs.readFileSync(path.join(root, file), 'utf8'), file);
run(fs.readFileSync(path.join(root, 'tests/mail-button-layout.lua'), 'utf8'), 'tests/mail-button-layout.lua');
run(fs.readFileSync(path.join(root, 'tests/bulk-add.lua'), 'utf8'), 'tests/bulk-add.lua');
run(fs.readFileSync(path.join(root, 'tests/quantity-and-toggle.lua'), 'utf8'), 'tests/quantity-and-toggle.lua');
run(fs.readFileSync(path.join(root, 'tests/dropdown-icons.lua'), 'utf8'), 'tests/dropdown-icons.lua');
run(fs.readFileSync(path.join(root, 'tests/item-classification.lua'), 'utf8'), 'tests/item-classification.lua');
run(fs.readFileSync(path.join(root, 'tests/quantity-pending.lua'), 'utf8'), 'tests/quantity-pending.lua');
run(fs.readFileSync(path.join(root, 'tests/stack-identity.lua'), 'utf8'), 'tests/stack-identity.lua');
}
suite(11509, ['tests/behavior.lua', 'tests/features.lua', 'tests/material-data.lua', 'tests/rule-drop.lua', 'tests/item-rules-panel.lua']);
suite(38002, ['tests/titan.lua', 'tests/material-data.lua', 'tests/rule-drop.lua', 'tests/item-rules-panel.lua']);
suite(16001, ['tests/client-smoke.lua', 'tests/material-data.lua', 'tests/rule-drop.lua', 'tests/item-rules-panel.lua']);
console.log(`PASS: ${files.length} 个 Lua 文件通过 Lua 5.1 语法检查、TOC 加载及模拟行为测试。`);
