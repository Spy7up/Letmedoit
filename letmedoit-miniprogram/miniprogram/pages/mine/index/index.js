const taskApi = require('../../../services/task')
const helperApi = require('../../../services/helper')
const auth = require('../../../services/auth')
const versionApi = require('../../../services/version')
const avatar = require('../../../utils/avatar')
const entry = require('../../../utils/entry')
const { presentUser } = require('../../../utils/present')

Page({
  data: {
    user: null,
    stats: { sentCount: 0, completedCount: 0, onTimeRate: 1, helperCount: 0 },
    rateText: '100%',
    // 版本号一律由接口下发（services/version.js），页面里不写死
    version: '',
    versionNote: '',
  },

  onLoad() {
    this.bootstrap()
  },

  onShow() {
    if (typeof this.getTabBar === 'function' && this.getTabBar()) {
      this.getTabBar().setData({ selected: 2 })
    }
    if (this.ready) this.load()
  },

  async bootstrap() {
    if (await entry.ensureEntry('pages/mine/index/index')) return
    this.ready = true
    this.load()
    this.loadVersion()
  },

  /**
   * 版本号来自 /api/version/current（后台统一维护）
   * <p>
   * 拿不到就留空，页面照常显示 —— 版本号只影响展示，不能让它挡住其它内容。
   */
  async loadVersion(refresh) {
    try {
      const v = await versionApi.current({ refresh })
      this.setData({
        version: v.versionLabel || v.version || '',
        versionNote: v.releaseNote || '',
      })
    } catch (e) {
      // 接口不可用且本地没缓存：保持空，模板会自动不显示
    }
  },

  async load() {
    let user = null
    try {
      user = await getApp().refreshUser()
      // 本机预览头像只对「我」生效，所以只在这里叠加，其余页面统一走默认头像
      this.setData({ user: avatar.withLocalAvatar(presentUser(user)) })
    } catch (e) {
      // 资料失败就保留上一次，统计继续拉
    }

    // 会员资料里暂时可能没有邀请码（老版本接口），用帮手邀请码接口兜住，别让页面空着
    if (user && !user.inviteCode) {
      try {
        const invite = await helperApi.getInvite()
        if (invite && invite.inviteCode) this.setData({ 'user.inviteCode': invite.inviteCode })
      } catch (e) {
        // 邀请码取不到就显示占位符
      }
    }

    try {
      const s = await taskApi.stats()
      this.setData({
        stats: s,
        rateText: Math.round((s.onTimeRate || 0) * 100) + '%',
      })
    } catch (e) {
      // 统计失败不影响页面主体
    }
  },

  goProfile() {
    wx.navigateTo({ url: '/pages/mine/profile/index' })
  },

  /**
   * 本机预览的头像失效了（微信回收了临时文件）：清掉缓存，模板自动回落成名字首字色块。
   * 这是"永远有头像"的兜底，别删。
   */
  onAvatarError() {
    avatar.clearLocal()
    if (this.data.user) this.setData({ 'user.avatarUrl': '' })
  },

  goMessages() {
    wx.navigateTo({ url: '/pages/messages/index/index' })
  },

  /** 用户协议 / 隐私政策：正文从后端取，运营改内容不用发版 */
  goAgreement(e) {
    const type = e.currentTarget.dataset.type === 'privacy' ? 'privacy' : 'user'
    wx.navigateTo({ url: '/pages/agreement/index?type=' + type })
  },

  /** 问题与反馈 */
  goFeedback() {
    wx.navigateTo({ url: '/pages/mine/feedback/index' })
  },

  about() {
    const version = this.data.version
    const note = this.data.versionNote ? this.data.versionNote + '\n\n' : ''
    wx.showModal({
      title: version ? '让我做 ' + version : '让我做',
      content: note + '别人让你做的小事，说一遍就够。\n\n有事直接说，别靠记性。',
      showCancel: false,
      confirmText: '知道了',
    })
  },

  /**
   * 注销账号（不可逆）
   * <p>
   * 微信审核对「有账号体系却没注销入口」的小程序会驳回；
   * 《个人信息保护法》也要求提供删除个人信息的途径。
   * 连续两次确认，避免误点。
   */
  cancelAccount() {
    wx.showModal({
      title: '注销账号？',
      content: '昵称、头像、手机号、邀请码和帮手关系都会被清除，且无法恢复。\n你参与的旧任务仍会留给其他人，只是显示为「已注销用户」。',
      confirmText: '继续',
      confirmColor: '#D64545',
      success: (res) => {
        if (!res.confirm) return
        wx.showModal({
          title: '再确认一次',
          content: '真的要注销并删除个人资料吗？',
          confirmText: '确认注销',
          confirmColor: '#D64545',
          success: (second) => {
            if (second.confirm) this.doCancelAccount()
          },
        })
      },
    })
  },

  async doCancelAccount() {
    if (this.cancelling) return
    this.cancelling = true
    wx.showLoading({ title: '处理中…', mask: true })
    try {
      await auth.cancelAccount()
      wx.hideLoading()
      wx.showToast({ title: '账号已注销', icon: 'none' })
      setTimeout(() => wx.reLaunch({ url: '/pages/launch/index' }), 800)
    } catch (e) {
      wx.hideLoading()
      wx.showToast({ title: e.message || '注销失败，请稍后再试', icon: 'none' })
      this.cancelling = false
    }
  },

  logout() {
    wx.showModal({
      title: '退出登录？',
      content: '退出后需要重新授权才能继续使用。',
      confirmText: '退出',
      confirmColor: '#D64545',
      success: (res) => {
        if (!res.confirm) return
        require('../../../services/auth').logout()
      },
    })
  },

  async onPullDownRefresh() {
    await this.load()
    // 版本不常变，但下拉时顺手取最新的，后台改了不用重启小程序
    await this.loadVersion(true)
    wx.stopPullDownRefresh()
  },
})
