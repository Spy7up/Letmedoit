/**
 * 用户协议与隐私政策
 *
 * 内容全部来自后端（t_app_agreement），运营者在后台改完立刻生效，
 * 小程序端不写死任何正文。
 */
const { http } = require('../utils/request')

/**
 * 当前生效的协议摘要（登录页用）
 * @returns {Promise<{userAgreement:object, privacyPolicy:object, version:string}>}
 */
function current() {
  return http.get('/api/agreement/current', null, { auth: false })
}

/**
 * 协议全文
 * @param {'user'|'privacy'} type
 * @returns {Promise<{type,title,version,effectiveTime,content}>}
 */
function detail(type) {
  return http.get('/api/agreement/detail', { type }, { auth: false })
}

/**
 * 把纯文本正文切成可渲染的块
 *
 * 约定的轻量格式（不是完整 Markdown，够用就行）：
 *   # 一级标题 / ## 二级 / ### 三级
 *   | a | b |  表格（第二行 --- 分隔自动跳过）
 *   其余按段落
 *
 * @param {string} content
 * @returns {Array<{type:string, text?:string, rows?:string[][]}>}
 */
function parse(content) {
  const blocks = []
  if (!content) return blocks

  let table = null
  content.split('\n').forEach((raw) => {
    const line = String(raw || '').trim()

    if (!line) {
      table = null
      blocks.push({ type: 'gap' })
      return
    }
    // 表格分隔行 | --- | --- |
    if (/^\|[\s:|-]+\|$/.test(line)) return
    if (line.charAt(0) === '|') {
      const cells = line.split('|').slice(1, -1).map((s) => s.trim())
      if (!table) {
        table = { type: 'table', rows: [] }
        blocks.push(table)
      }
      table.rows.push(cells)
      return
    }

    table = null
    if (line.indexOf('### ') === 0) blocks.push({ type: 'h3', text: line.slice(4) })
    else if (line.indexOf('## ') === 0) blocks.push({ type: 'h2', text: line.slice(3) })
    else if (line.indexOf('# ') === 0) blocks.push({ type: 'h1', text: line.slice(2) })
    else blocks.push({ type: 'p', text: line })
  })
  return blocks
}

module.exports = { current, detail, parse }
