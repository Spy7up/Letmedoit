const taskApi = require('../../../services/task')
const entry = require('../../../utils/entry')
const { presentDetail } = require('../../../utils/present')

/** 详情 + 底部操作条模式（accept / complete / creator / none） */
function withBar(d) {
  const p = presentDetail(d)
  p.meId = (d.me && d.me.userId) || ''
  // 撤回已挪到底部悬浮条，这里只决定底部显示哪一组
  p.barMode =
    d.me && d.me.canAccept
      ? 'accept'
      : d.me && d.me.canComplete
      ? 'complete'
      : d.isCreator
      ? 'creator'
      : 'none'
  return p
}

Page({
  data: {
    task: null,
    loading: true,
    error: '',
    acting: '',
  },

  onLoad(options) {
    this.taskId = options.id || ''
    // 旧版分享卡片仍然会落到这个页面（新卡片走 receive 页），所以同样记下完整路径
    this.route = entry.routeOf('pages/tasks/detail/index', options)
    if (!this.taskId) {
      this.setData({ loading: false, error: '缺少任务 id' })
      return
    }
    this.bootstrap()
  },

  onShow() {
    if (this.ready) this.load(true)
  },

  async bootstrap() {
    // 没登录过就从分享卡片进来了：先登录 + 补头像昵称，回来再加载
    if (await entry.ensureEntry(this.route)) return
    this.ready = true
    this.load()
  },

  async load(silent) {
    if (!silent) this.setData({ loading: true, error: '' })
    try {
      const d = await taskApi.detail(this.taskId)
      this.setData({
        task: withBar(d),
        loading: false,
        error: '',
      })
    } catch (e) {
      this.setData({ loading: false, error: e.message || '没加载出来' })
    }
  },

  onRetry() {
    this.load()
  },

  /* ---------------- 我的操作 ---------------- */

  async onAccept() {
    if (this.data.acting) return
    this.setData({ acting: 'accept' })
    try {
      const d = await taskApi.accept(this.taskId)
      this.setData({ task: withBar(d) })
      wx.vibrateShort({ type: 'light' })
      wx.showToast({ title: '已接下，开始吧', icon: 'none' })
    } catch (e) {
      wx.showToast({ title: e.message || '操作失败', icon: 'none' })
      this.load(true)
    } finally {
      this.setData({ acting: '' })
    }
  },

  onReject() {
    wx.showModal({
      title: '说说为什么',
      editable: true,
      placeholderText: '比如：今晚不在家',
      confirmText: '拒绝',
      success: (res) => {
        if (!res.confirm) return
        const reason = (res.content || '').trim()
        if (!reason) {
          wx.showToast({ title: '还是说一句吧', icon: 'none' })
          return
        }
        // 多人任务里，拒绝的是"我这份"，任务本身继续
        taskApi
          .reject(this.taskId, reason)
          .then((d) => {
            this.setData({ task: withBar(d) })
            wx.showToast({ title: '已回复对方', icon: 'none' })
          })
          .catch((e) => wx.showToast({ title: e.message || '操作失败', icon: 'none' }))
      },
    })
  },

  goComplete() {
    wx.navigateTo({ url: '/pages/tasks/complete/index?id=' + this.taskId })
  },

  async onRemind() {
    if (this.data.acting) return
    this.setData({ acting: 'remind' })
    try {
      await taskApi.remind(this.taskId)
      wx.showToast({ title: '已提醒', icon: 'none' })
      this.load(true)
    } catch (e) {
      wx.showToast({ title: e.message || '刚催过啦', icon: 'none' })
    } finally {
      this.setData({ acting: '' })
    }
  },

  goEdit() {
    wx.navigateTo({ url: '/pages/tasks/create/index?taskId=' + this.taskId })
  },

  goAdd() {
    wx.navigateTo({ url: '/pages/tasks/participants/index?taskId=' + this.taskId + '&mode=add' })
  },

  confirmCancel() {
    const t = this.data.task
    const started = t.status === 'in_progress'
    wx.showModal({
      title: '撤回这条任务？',
      content: started ? 'TA 们已经开始了，撤回后就不能再提交了。' : '撤回后对方会看到"已撤回"。',
      confirmText: '撤回',
      confirmColor: '#D64545',
      success: (res) => {
        if (!res.confirm) return
        taskApi
          .cancel(this.taskId)
          .then((d) => {
            this.setData({ task: withBar(d) })
            wx.showToast({ title: '已撤回', icon: 'none' })
          })
          .catch((e) => wx.showToast({ title: e.message || '操作失败', icon: 'none' }))
      },
    })
  },

  /**
   * 删除任务（只有「已撤回」的才给这个按钮，权限位来自服务端 canDelete）
   * <p>
   * 删除不可逆，必须二次确认：第一次点是「删除」按钮，这里弹的框才是真正的确认。
   */
  confirmDelete() {
    const t = this.data.task
    const shared = t.totalCount > 1 ? '这条任务 ' + t.totalCount + ' 个人都看得到，' : ''
    wx.showModal({
      title: '删除这条任务？',
      content: shared + '删除后谁也看不到了，也恢复不了。',
      confirmText: '删除',
      confirmColor: '#D64545',
      success: (res) => {
        if (res.confirm) this.doDelete()
      },
    })
  },

  async doDelete() {
    if (this.data.acting) return
    this.setData({ acting: 'delete' })
    try {
      await taskApi.remove(this.taskId)
      // 列表页 onShow 会重新拉一次，这里只标记一下，避免来回传参
      getApp().globalData.needRefresh = true
      wx.showToast({ title: '已删除', icon: 'none' })
      setTimeout(() => this.back(), 500)
    } catch (e) {
      wx.showToast({ title: e.message || '删除失败，再试一次', icon: 'none' })
      this.setData({ acting: '' })
      this.load(true)
    }
  },

  /** 删除后回列表：直接从分享卡片进来的没有上一页，退回任务首页 */
  back() {
    if (getCurrentPages().length > 1) {
      wx.navigateBack()
      return
    }
    // 任务首页是 tabBar 页，只能用 switchTab（redirectTo 会静默失败）
    wx.switchTab({ url: '/pages/tasks/index/index' })
  },

  /**
   * 举报这条任务
   * <p>
   * UGC 类小程序必须让用户能举报违规内容（审核会查）。
   * 直接跳到反馈页并预选「内容违规」，用户不用自己找分类。
   */
  goReport() {
    const t = this.data.task
    const title = (t && t.title) || ''
    const content = '举报任务：' + title + '（ID ' + this.taskId + '）\n原因：'
    wx.navigateTo({
      url: '/pages/mine/feedback/index?type=3&content=' + encodeURIComponent(content),
    })
  },

  /* ---------------- 查看某人的备注 ---------------- */
  /**
   * 看大图
   * dataset: index = 第几个参与者，pi = 第几张图
   */
  previewImage(e) {
    const { index, pi } = e.currentTarget.dataset
    const p = this.data.task.participants[index]
    if (!p || !(p.images || []).length) return
    wx.previewImage({ current: p.images[pi], urls: p.images })
  },

  /** 布置时给的参考图：点开看大图，从点的那张开始 */
  previewTaskImage(e) {
    const list = (this.data.task && this.data.task.allShots) || []
    if (!list.length) return
    const idx = Number(e.currentTarget.dataset.index) || 0
    wx.previewImage({ current: list[idx] || list[0], urls: list })
  },

  async onPullDownRefresh() {
    await this.load(true)
    wx.stopPullDownRefresh()
  },

  onShareAppMessage() {
    const t = this.data.task
    if (!t) {
      return { title: '让我做 · 别人让你做的小事，说一遍就够', path: '/pages/tasks/index/index' }
    }
    // 转发走「接收页」而不是详情页：点开的人只需要接受/拒绝，不需要看时间线和参与者。
    // 卡片标题超过 2 行会被微信截断，所以任务名先按 12 字收一下。
    const short = t.title.length > 12 ? t.title.slice(0, 12) + '…' : t.title
    return {
      title: t.creator.nickname + ' 让你做：' + short + ' · ' + t.deadlineText,
      path: '/pages/tasks/receive/index?id=' + this.taskId,
      // 有任务附图就用第一张当封面；没有就用默认封面（留空微信用页面截图，很丑）
      imageUrl: (t.allShots && t.allShots[0]) || '/images/share/task-cover.png',
    }
  },
})
