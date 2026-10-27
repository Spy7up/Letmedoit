/**
 * 版本信息
 *
 * 小程序里**所有**版本的文案都从这里取，页面里不写死 "v1.1.0"。
 * 版本由后台统一维护（t_app_version），改版本不用重新发版：
 *   GET /api/version/current → { version, versionLabel, releaseNote, releaseTime }
 *
 * 两级缓存：
 *  1. 内存：一次会话内只请求一次；
 *  2. 本地存储：接口挂了/没网时用上次拿到的，保证「我的」页不会因为版本号而空白。
 */
const { http } = require('../utils/request')

const CACHE_KEY = 'lmd_app_version'

let memory = null

function readCache() {
  try {
    const cached = wx.getStorageSync(CACHE_KEY)
    return cached && cached.version ? cached : null
  } catch (e) {
    return null
  }
}

function writeCache(value) {
  try {
    wx.setStorageSync(CACHE_KEY, value)
  } catch (e) {
    // 存不下不影响本次展示
  }
}

/**
 * 当前版本
 *
 * @param {{refresh?:boolean}} options refresh=true 时忽略内存缓存重新拉
 * @returns {Promise<{version:string, versionLabel:string, releaseNote:string, releaseTime:string}>}
 */
async function current(options) {
  const opt = options || {}
  if (memory && !opt.refresh) return memory

  try {
    const vo = await http.get('/api/version/current', null, { auth: false })
    const value = {
      version: (vo && vo.version) || '',
      versionLabel: (vo && vo.versionLabel) || '',
      releaseNote: (vo && vo.releaseNote) || '',
      releaseTime: (vo && vo.releaseTime) || '',
    }
    // 接口通但没配版本（后台还没发过版），不要污染本地缓存
    if (value.version) {
      memory = value
      writeCache(value)
    }
    return value
  } catch (e) {
    const cached = readCache()
    if (cached) return cached
    throw e
  }
}

module.exports = { current }
