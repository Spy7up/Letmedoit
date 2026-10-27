const feedbackApi = require('../../../services/feedback')
const fileApi = require('../../../services/file')
const entry = require('../../../utils/entry')

Page({
  data: {
    types: [],
    type: 0,
    content: '',
    images: [],
    maxImages: 3,
    maxLength: 500,
    loadingTypes: true,
    uploading: false,
    submitting: false,
  },

  /**
   * 支持从别处带参进来：
   *   ?type=3&content=xxx —— 任务详情页的「举报」就是这个入口，
   *   用户不用自己找分类、也不用重新描述是哪条任务。
   */
  onLoad(options) {
    const opt = options || {}
    this.preset = {
      type: Number(opt.type) || 0,
      content: safeDecode(opt.content || ''),
    }
    this.bootstrap()
  },

  async bootstrap() {
    // 反馈要带身份（后台要能回溯是谁遇到的问题），没登录先走登录
    if (await entry.ensureEntry('pages/mine/feedback/index')) return
    if (this.preset.content) {
      this.setData({ content: this.preset.content.slice(0, this.data.maxLength) })
    }
    this.loadTypes()
  },

  /**
   * 类型列表由后端下发（字典 FEEDBACK_TYPE），默认选「使用问题」——
   * 从「我的」点进来的绝大多数是遇到了问题，少一次点击。
   */
  async loadTypes() {
    if (this.data.loadingTypes === false && this.data.types.length) return
    this.setData({ loadingTypes: true })
    try {
      const types = await feedbackApi.types()
      // 带参进来的优先用指定类型（举报固定「内容违规」），否则默认「使用问题」
      const picked = this.preset && this.preset.type
        ? types.filter((t) => t.value === this.preset.type)[0]
        : null
      const bug = types.filter((t) => t.value === 2)[0]
      this.setData({
        types,
        type: (picked || bug || types[0] || {}).value || 0,
        loadingTypes: false,
      })
    } catch (e) {
      this.setData({ loadingTypes: false })
      wx.showToast({ title: '类型没加载出来，点一下重试', icon: 'none' })
    }
  },

  pickType(e) {
    this.setData({ type: Number(e.currentTarget.dataset.value) })
  },

  onContent(e) {
    this.setData({ content: e.detail.value })
  },

  chooseImage() {
    const left = this.data.maxImages - this.data.images.length
    if (left <= 0 || this.data.uploading) return
    wx.chooseMedia({
      count: left,
      mediaType: ['image'],
      sizeType: ['compressed'],
      success: (res) => {
        this.uploadAll(res.tempFiles.map((f) => f.tempFilePath))
      },
    })
  },

  /**
   * 逐张传到对象存储，成功才进列表
   * 列表里必须存公网 URL：微信临时路径换台设备就失效了
   */
  async uploadAll(paths) {
    this.setData({ uploading: true })
    const images = this.data.images.slice()
    let failed = 0
    for (const path of paths) {
      try {
        const file = await fileApi.uploadImage(path, 'feedback-image')
        images.push(file.url)
        this.setData({ images: images.slice() })
      } catch (e) {
        failed++
      }
    }
    this.setData({ uploading: false })
    if (failed) {
      wx.showToast({ title: failed + ' 张没传上，再选一次', icon: 'none' })
    }
  },

  removeImage(e) {
    const images = this.data.images.slice()
    images.splice(e.currentTarget.dataset.index, 1)
    this.setData({ images })
  },

  previewImage(e) {
    const idx = e.currentTarget.dataset.index
    wx.previewImage({ current: this.data.images[idx], urls: this.data.images })
  },

  async submit() {
    if (this.data.submitting) return
    const content = this.data.content.trim()
    if (!this.data.type) {
      wx.showToast({ title: '先选个反馈类型', icon: 'none' })
      return
    }
    if (!content) {
      wx.showToast({ title: '说说遇到的情况吧', icon: 'none' })
      return
    }
    if (this.data.uploading) {
      wx.showToast({ title: '图片还在上传，稍等一下', icon: 'none' })
      return
    }

    this.setData({ submitting: true })
    try {
      await feedbackApi.submit({
        type: this.data.type,
        content,
        images: this.data.images,
      })
      wx.showToast({ title: '收到了，谢谢你', icon: 'none' })
      setTimeout(() => wx.navigateBack(), 800)
    } catch (e) {
      wx.showToast({ title: e.message || '提交失败，再试一次', icon: 'none' })
      this.setData({ submitting: false })
    }
  },
})

/** 查询参数可能已经被框架解码过，再解一次容易抛错，兜住 */
function safeDecode(text) {
  if (!text) return ''
  try {
    return decodeURIComponent(text)
  } catch (e) {
    return text
  }
}
