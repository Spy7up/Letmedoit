/**
 * 问题与反馈
 *
 * 页面只调这里：类型列表、提交。反馈没有「列表」接口 —— 这期是单向通道，
 * 后台处理完要回复用户时再加「我的反馈」（表里已经留好 reply_* 字段）。
 *
 * 后端接口见 letmedoit-api/docs/问题与反馈.md。
 */
const { http } = require('../utils/request')

/**
 * 反馈类型
 * <p>
 * 文案由后端下发（数据字典 FEEDBACK_TYPE），后台改一个词小程序不用发版，
 * 所以这里不写死「功能建议 / 使用问题」。
 *
 * @returns {Promise<Array<{value:number, label:string}>>}
 */
function types() {
  return http.get('/api/feedback/type/list').then((list) =>
    (list || []).map((item) => ({
      value: Number(item.value),
      label: item.label || '',
    }))
  )
}

/**
 * 提交反馈
 *
 * @param {{type:number, content:string, images?:string[], contact?:string}} dto
 * @returns {Promise<number>} 反馈ID
 */
function submit(dto) {
  const body = {
    type: Number(dto.type),
    content: dto.content,
    images: (dto.images || []).slice(),
  }
  if (dto.contact) body.contact = dto.contact
  return http.post('/api/feedback/add', body, { loading: '提交中…' })
}

module.exports = { types, submit }
