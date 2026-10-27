const helperApi = require('../../../services/helper')
const { presentUser } = require('../../../utils/present')

Page({
  data: {
    helper: null,
    count: 0,
  },

  onLoad(options) {
    this.helperId = options.fid || ''
    const name = decodeURIComponent(options.name || '帮手')
    // 先用 URL 里的名字 + 色块顶上，避免白屏；头像要靠列表补
    const u = presentUser({ id: options.uid || name, nickname: name })
    this.setData({
      helper: Object.assign(u, { uid: options.uid || '' }),
      count: Number(options.count || 0),
    })
    this.fillFromList()
  },

  /**
   * 补头像
   *
   * 上一页跳过来时 URL 里只有名字和 id，装不下 avatarUrl（云上是长链接），
   * 所以进来后按 uid 从帮手列表捞一次，拿回真实头像和备注名。
   * 直接用 URL 参数拼出来的对象永远只有色块。
   */
  async fillFromList() {
    const uid = (this.data.helper && this.data.helper.uid) || ''
    if (!uid) return
    try {
      const helpers = await helperApi.list()
      const hit = helpers.filter((f) => String(f.userId) === String(uid))[0]
      if (!hit) return
      this.setData({
        // id 用 userId，和帮手列表页的色块配色保持一致，不会换个页面就变个颜色
        helper: Object.assign(
          presentUser({
            id: hit.userId,
            nickname: hit.remark || hit.nickname,
            avatarUrl: hit.avatarUrl,
          }),
          { uid: String(hit.userId) }
        ),
        count: hit.activeTaskCount || this.data.count,
      })
    } catch (e) {
      // 拉不到就保持 URL 里的名字 + 色块头像，解除帮手不受影响
    }
  },

  assign() {
    wx.navigateTo({ url: '/pages/tasks/create/index?assigneeIds=' + this.data.helper.uid })
  },

  remove() {
    wx.showModal({
      title: '解除帮手关系？',
      content: '解除后不能再给对方派活，正在进行的任务不受影响。',
      confirmText: '解除',
      confirmColor: '#D64545',
      success: (res) => {
        if (!res.confirm) return
        helperApi
          .remove(this.helperId)
          .then(() => {
            wx.showToast({ title: '已解除', icon: 'none' })
            getApp().globalData.needRefresh = true
            setTimeout(() => wx.navigateBack(), 600)
          })
          .catch((e) => wx.showToast({ title: e.message || '操作失败', icon: 'none' }))
      },
    })
  },
})
