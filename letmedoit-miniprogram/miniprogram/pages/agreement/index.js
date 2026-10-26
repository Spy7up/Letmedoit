const agreementApi = require('../../services/agreement')

const TITLES = {
  user: '用户协议',
  privacy: '隐私政策',
}

Page({
  data: {
    type: 'user',
    title: '',
    version: '',
    effectiveDate: '',
    blocks: [],
    loading: true,
    error: '',
  },

  onLoad(options) {
    const type = options && options.type === 'privacy' ? 'privacy' : 'user'
    this.setData({ type, title: TITLES[type] })
    wx.setNavigationBarTitle({ title: TITLES[type] })
    this.load(type)
  },

  /**
   * 正文全部来自后端，不在小程序里写死：
   * 运营者在后台改了协议，用户下次进来看到的就是新版本。
   */
  async load(type) {
    this.setData({ loading: true, error: '' })
    try {
      const doc = await agreementApi.detail(type)
      this.setData({
        title: doc.title || TITLES[type],
        version: doc.version || '',
        effectiveDate: formatDate(doc.effectiveTime),
        blocks: agreementApi.parse(doc.content),
        loading: false,
      })
    } catch (e) {
      this.setData({ loading: false, error: e.message || '加载失败，请稍后重试' })
    }
  },

  retry() {
    this.load(this.data.type)
  },
})

/** 生效日期只留 yyyy-MM-dd，ISO 串在小屏上太占地方 */
function formatDate(value) {
  if (!value) return ''
  const text = String(value)
  const hit = text.match(/^(\d{4})-(\d{2})-(\d{2})/)
  if (hit) return hit[1] + '-' + hit[2] + '-' + hit[3]
  return text.slice(0, 10)
}
