/**
 * 隐私授权弹窗
 *
 * 微信从 2023-09 起要求：调用隐私接口（选相册、拍照、选头像等）之前，
 * 用户必须先同意《小程序用户隐私保护指引》。没同意就调，接口直接失败。
 *
 * 同意按钮必须是原生 button 且 open-type="agreePrivacyAuthorization"，
 * 点了它微信才会把「已同意」同步到自己那边；普通 view 点了没用。
 *
 * 基础库 2.32.3 起支持 wx.getPrivacySetting；低版本没有该接口时不弹窗，
 * 让业务照常走（微信对老基础库不做强制）。
 */
Component({
  data: {
    show: false,
  },

  lifetimes: {
    attached() {
      this.check()
    },
  },

  methods: {
    check() {
      if (!wx.getPrivacySetting) return
      wx.getPrivacySetting({
        success: (res) => {
          if (res && res.needAuthorization) this.setData({ show: true })
        },
        fail: () => {},
      })
    },

    /** 打开后台配置的《小程序用户隐私保护指引》全文 */
    openContract() {
      if (wx.openPrivacyContract) wx.openPrivacyContract({})
    },

    /** 同意后由微信回调，此时才真正解锁隐私接口 */
    onAgree() {
      this.setData({ show: false })
      this.triggerEvent('agree')
    },

    /** 不同意不阻断基础功能（任务列表、详情都还能看），只是不能传图和选头像 */
    onDisagree() {
      this.setData({ show: false })
      wx.showToast({ title: '不同意就无法上传图片或设置头像', icon: 'none' })
    },

    noop() {},
  },
})
