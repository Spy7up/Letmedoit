#!/usr/bin/env node
/**
 * 微信消息推送验签自检工具
 *
 * 用途：排查「微信消息推送验签失败」。微信的签名算法是
 *       sha1(字典序排序后的 token、timestamp、nonce 拼接)
 * 把微信后台的 Token 和日志里那三个值输进来，看算出的签名能不能对上：
 *
 *   对上了 → 说明服务器上生效的 WX_PUSH_TOKEN 不是这个值（没注入 / 没重启）
 *   对不上 → 说明微信后台填的 Token 和你以为的不一样
 *
 * 用法：
 *   node wx-push-sign.js <token> <timestamp> <nonce> [日志里的 signature]
 *
 * 例：
 *   node wx-push-sign.js mytoken123 1793028551 1175836500 2a71c085aba57c49a56ef4560a1bea52d737411f
 */
const crypto = require('crypto')

const [, , token, timestamp, nonce, signature] = process.argv

if (!token || !timestamp || !nonce) {
  console.log('用法: node wx-push-sign.js <token> <timestamp> <nonce> [signature]')
  console.log('例:   node wx-push-sign.js mytoken123 1793028551 1175836500 2a71c085...')
  process.exit(2)
}

// 微信的字典序排序是普通字符串排序，不是按长度
const raw = [token, timestamp, nonce].sort().join('')
const expected = crypto.createHash('sha1').update(raw, 'utf8').digest('hex')

console.log('token     :', token.length > 40 ? token.slice(0, 40) + '…' : token, `(长度 ${token.length})`)
console.log('timestamp :', timestamp)
console.log('nonce     :', nonce)
console.log('拼接明文  :', raw)
console.log('算出签名  :', expected)

if (signature) {
  const ok = expected.toLowerCase() === String(signature).toLowerCase()
  console.log('日志签名  :', signature)
  console.log(ok ? '\n✅ 一致：这个 Token 就是微信后台在用的那个' : '\n❌ 不一致：Token 不对')
  console.log(ok
    ? '   → 那问题在服务器：确认 WX_PUSH_TOKEN 已注入并且后端重启过'
    : '   → 那问题在 Token：核对微信后台「开发管理 - 消息推送 - Token」')
  process.exit(ok ? 0 : 1)
}
