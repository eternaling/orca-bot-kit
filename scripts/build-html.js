#!/usr/bin/env node
/**
 * 把 docs/orca-map.md 编译成一份自包含的 docs/orca-map.html。
 *
 * 为什么需要它：以前两份 HTML 是 md 的手抄副本，check.sh 只能查结构，抓不住"内容漏抄"。
 * 现在内容型 HTML 由本脚本生成 —— 生成结果与提交版不一致时 check.sh 直接失败，
 * 漏抄这种事不可能再悄悄发生。
 *
 * 用法：
 *   node scripts/build-html.js          重新生成 docs/orca-map.html
 *   node scripts/build-html.js --check  只比对，不一致则退出 1（check.sh 用它）
 *
 * 零依赖，只支持 docs/orca-map.md 实际用到的 Markdown 子集：
 * 标题(h1-h3) / 表格(含对齐) / 有序与无序列表 / 围栏代码块 / 分割线 / 段落
 * 行内：`code`、**粗体**、其余原样（该文件里的 <b> 等标签是有意写的）
 */
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.resolve(__dirname, '..');
const MD = path.join(ROOT, 'docs', 'orca-map.md');
const OUT = path.join(ROOT, 'docs', 'orca-map.html');
const VER = path.join(ROOT, 'VERSION');

// 统一成 LF 再处理：否则本地工作副本（CRLF）与克隆（LF）会生成不同的 HTML，
// check.sh 的「重新生成逐字比对」会在克隆里误报不同步。
const mdRaw = fs.readFileSync(MD, 'utf8');
const md = mdRaw.replace(/\r\n/g, '\n');
const version = fs.readFileSync(VER, 'utf8').trim();
const fingerprint = crypto.createHash('sha256').update(md, 'utf8').digest('hex').slice(0, 8);

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

/** 行内渲染：先保护 `code`，再处理 **粗体**，其余原样保留（允许写入者有意嵌入的 HTML） */
function inline(text) {
  const codes = [];
  let s = text.replace(/`([^`]+)`/g, (_, c) => {
    codes.push('<code>' + esc(c) + '</code>');
    return '\u0000' + (codes.length - 1) + '\u0000';
  });
  s = s.replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>');
  s = s.replace(/\u0000(\d+)\u0000/g, (_, i) => codes[Number(i)]);
  return s;
}

const slug = (s) =>
  s
    .replace(/<[^>]+>/g, '')
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-|-$/g, '')
    .toLowerCase() || 'sec';

const lines = md.split(/\r?\n/);
const out = [];
const toc = [];
let i = 0;
let secIdx = 0;

function isBlockStart(line) {
  return (
    /^```/.test(line) ||
    /^#{1,3} /.test(line) ||
    /^\|/.test(line) ||
    /^[-*] /.test(line) ||
    /^\d+\. /.test(line) ||
    /^---$/.test(line)
  );
}

while (i < lines.length) {
  const line = lines[i];

  // 围栏代码块
  if (/^```/.test(line)) {
    const lang = line.slice(3).trim();
    const buf = [];
    i++;
    while (i < lines.length && !/^```/.test(lines[i])) buf.push(lines[i++]);
    i++; // 跳过收尾 ```
    out.push(
      '<pre' + (lang ? ` data-lang="${esc(lang)}"` : '') + '><code>' + esc(buf.join('\n')) + '</code></pre>'
    );
    continue;
  }

  // 分割线
  if (/^---$/.test(line)) {
    out.push('<hr>');
    i++;
    continue;
  }

  // 标题
  const h = /^(#{1,3}) (.*)$/.exec(line);
  if (h) {
    const level = h[1].length;
    const text = h[2].trim();
    const id = 's' + ++secIdx + '-' + slug(text);
    if (level <= 2) toc.push({ level, text: text.replace(/[*`]/g, ''), id });
    out.push(`<h${level} id="${id}">${inline(text)}</h${level}>`);
    i++;
    continue;
  }

  // 表格
  if (/^\|/.test(line)) {
    const rows = [];
    while (i < lines.length && /^\|/.test(lines[i])) rows.push(lines[i++]);
    const cells = (r) =>
      r.replace(/^\|/, '').replace(/\|$/, '').split('|').map((c) => c.trim());
    const head = cells(rows[0]);
    const aligns = cells(rows[1] || '').map((a) => {
      if (/^:-+:$/.test(a)) return 'center';
      if (/^-+:$/.test(a)) return 'right';
      return 'left';
    });
    const body = rows.slice(2);
    let t = '<div class="tw"><table><thead><tr>';
    head.forEach((c, k) => {
      t += `<th style="text-align:${aligns[k] || 'left'}">${inline(c)}</th>`;
    });
    t += '</tr></thead><tbody>';
    for (const r of body) {
      const cs = cells(r);
      t += '<tr>';
      cs.forEach((c, k) => {
        t += `<td style="text-align:${aligns[k] || 'left'}">${inline(c)}</td>`;
      });
      t += '</tr>';
    }
    t += '</tbody></table></div>';
    out.push(t);
    continue;
  }

  // 有序列表
  if (/^\d+\. /.test(line)) {
    const items = [];
    while (i < lines.length && /^\d+\. /.test(lines[i])) {
      let item = lines[i].replace(/^\d+\. /, '');
      i++;
      // 缩进续行并入当前项
      while (i < lines.length && /^\s{2,}\S/.test(lines[i]) && !isBlockStart(lines[i].trim())) {
        item += ' ' + lines[i].trim();
        i++;
      }
      items.push(item);
    }
    out.push('<ol>' + items.map((x) => `<li>${inline(x)}</li>`).join('') + '</ol>');
    continue;
  }

  // 无序列表
  if (/^[-*] /.test(line)) {
    const items = [];
    while (i < lines.length && /^[-*] /.test(lines[i])) {
      let item = lines[i].replace(/^[-*] /, '');
      i++;
      while (i < lines.length && /^\s{2,}\S/.test(lines[i]) && !isBlockStart(lines[i].trim())) {
        item += ' ' + lines[i].trim();
        i++;
      }
      items.push(item);
    }
    out.push('<ul>' + items.map((x) => `<li>${inline(x)}</li>`).join('') + '</ul>');
    continue;
  }

  // 空行
  if (line.trim() === '') {
    i++;
    continue;
  }

  // 段落：吃到空行或下一个块
  const para = [];
  while (i < lines.length && lines[i].trim() !== '' && !isBlockStart(lines[i])) para.push(lines[i++]);
  out.push('<p>' + inline(para.join(' ')) + '</p>');
}

const tocHtml =
  '<nav class="toc"><b>目录</b><ul>' +
  toc
    .map((t) => `<li class="lv${t.level}"><a href="#${t.id}">${esc(t.text)}</a></li>`)
    .join('') +
  '</ul></nav>';

const html = `<!doctype html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Orca 地图 v${esc(version)}</title>
<style>
  :root{--fg:#17181c;--muted:#5f6470;--bd:#e3e4e9;--bg:#fff;--soft:#f7f8fa;--acc:#2563eb;--warn:#b45309}
  *{box-sizing:border-box}
  body{margin:0;background:var(--soft);color:var(--fg);line-height:1.65;
       font-family:system-ui,-apple-system,"Segoe UI","Microsoft YaHei",sans-serif;font-size:14px}
  .page{max-width:980px;margin:0 auto;padding:28px 20px 60px}
  .card{background:var(--bg);border:1px solid var(--bd);border-radius:12px;padding:26px 28px}
  header.bar{border-bottom:1px solid var(--bd);padding-bottom:14px;margin-bottom:18px}
  .badge{display:inline-block;font-size:11.5px;padding:2px 8px;border-radius:999px;
         border:1px solid var(--bd);background:var(--soft);color:var(--muted);margin-right:6px}
  .gen{font-size:12px;color:var(--muted);background:#fffbeb;border-left:3px solid var(--warn);
       padding:8px 12px;border-radius:0 6px 6px 0;margin:12px 0 0}
  nav.toc{background:var(--soft);border:1px solid var(--bd);border-radius:10px;padding:12px 16px;margin:18px 0 26px}
  nav.toc ul{margin:6px 0 0;padding-left:16px;columns:2;column-gap:26px}
  nav.toc li{font-size:12.5px;margin:1px 0;list-style:none}
  nav.toc li.lv1{font-weight:600;margin-top:6px}
  nav.toc a{color:var(--acc);text-decoration:none}
  nav.toc a:hover{text-decoration:underline}
  h1{font-size:21px;margin:34px 0 10px;padding-top:8px}
  h1:first-of-type{margin-top:8px}
  h2{font-size:16px;margin:26px 0 8px}
  h3{font-size:14px;margin:18px 0 6px;color:var(--muted)}
  p{margin:8px 0}
  hr{border:0;border-top:1px solid var(--bd);margin:26px 0}
  code{font-family:ui-monospace,SFMono-Regular,Consolas,monospace;font-size:12px;
       background:#eef0f4;border-radius:4px;padding:1px 5px}
  pre{background:#1f2430;color:#e6e8ee;border-radius:9px;padding:13px 15px;overflow-x:auto;margin:12px 0}
  pre code{background:none;color:inherit;padding:0;font-size:12.5px;white-space:pre}
  b{font-weight:650}
  ul,ol{margin:8px 0;padding-left:22px}
  li{margin:3px 0}
  .tw{overflow-x:auto;margin:12px 0}
  table{border-collapse:collapse;width:100%;font-size:12.5px;background:var(--bg)}
  th,td{border:1px solid var(--bd);padding:7px 10px;vertical-align:top}
  th{background:var(--soft);font-size:12px;color:var(--muted);font-weight:600}
  @media(max-width:640px){nav.toc ul{columns:1}.page{padding:16px 12px 40px}.card{padding:18px 15px}}
</style>
</head>
<body>
<div class="page">
<div class="card">
<header class="bar">
  <span class="badge">v${esc(version)}</span><span class="badge">md 指纹 ${esc(fingerprint)}</span>
  <span class="badge">事实基准 Orca 1.4.278</span>
  <div class="gen"><b>本文件由 <code>node scripts/build-html.js</code> 生成，不要手改。</b>
  内容与 <code>docs/orca-map.md</code> 同步（指纹不一致时 <code>check.sh</code> 会失败）。
  想看结构关系示意图，见 <code>orca-panorama.html</code> / <code>orca-workflow.html</code>（手工绘制，可能落后于 md）。</div>
</header>
${tocHtml}
${out.join('\n')}
</div>
</div>
</body>
</html>
`;

if (process.argv.includes('--check')) {
  const cur = fs.existsSync(OUT) ? fs.readFileSync(OUT, 'utf8') : '';
  if (cur !== html) {
    console.error('✗ docs/orca-map.html 与 orca-map.md 不同步（或未生成）');
    console.error('  跑 node scripts/build-html.js 重新生成后提交');
    process.exit(1);
  }
  console.log(`  orca-map.html 与 md 同步（v${version} 指纹 ${fingerprint}）`);
  process.exit(0);
}

fs.writeFileSync(OUT, html, 'utf8');
console.log(`已生成 docs/orca-map.html  v${version}  指纹 ${fingerprint}  ${(Buffer.byteLength(html) / 1024).toFixed(1)} KB`);
