// n8nのCodeノードに貼り付けるスクリプト
// 前のSlackノード2つ（#discoveries, #research-queue）の出力を整形して
// routine.shに渡すテキストファイルを生成する
//
// 入力: $('Get discoveries').all() と $('Get research-queue').all()
// 出力: { messagesFile: '/tmp/personal-os-messages.txt', date: 'YYYY-MM-DD' }

const fs = require('fs');

const date = new Date().toISOString().slice(0, 10);

// #discoveriesのメッセージを整形
const discoveries = $('Get discoveries').all();
let discoveriesText = `=== #discoveries (${date}) ===\n`;
if (discoveries.length === 0) {
  discoveriesText += '（新着なし）\n';
} else {
  for (const item of discoveries) {
    const msgs = item.json.messages || [];
    for (const msg of msgs) {
      const time = new Date(parseFloat(msg.ts) * 1000)
        .toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Tokyo' });
      const text = (msg.text || '').replace(/\n/g, ' ');
      if (text.trim()) {
        discoveriesText += `[${time}] ${text}\n`;
      }
    }
  }
}

// #research-queueのメッセージを整形
const researchQueue = $('Get research-queue').all();
let researchText = `\n=== #research-queue (${date}) ===\n`;
if (researchQueue.length === 0) {
  researchText += '（新着なし）\n';
} else {
  for (const item of researchQueue) {
    const msgs = item.json.messages || [];
    for (const msg of msgs) {
      const time = new Date(parseFloat(msg.ts) * 1000)
        .toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Tokyo' });
      const text = (msg.text || '').replace(/\n/g, ' ');
      if (text.trim()) {
        researchText += `[${time}] ${text}\n`;
      }
    }
  }
}

const content = discoveriesText + researchText;
const messagesFile = '/tmp/personal-os-messages.txt';
fs.writeFileSync(messagesFile, content, 'utf8');

return { messagesFile, date, preview: content.slice(0, 200) };
