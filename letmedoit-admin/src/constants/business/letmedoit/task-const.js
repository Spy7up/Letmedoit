/*
 * 让我做 · 任务相关枚举
 * 与小程序端 AppDictCode 一致，后台只读展示，不提供字典编辑
 *
 * @Author: 让我做
 */

// 任务聚合状态
export const TASK_STATUS_ENUM = {
  RESERVED: {
    value: 0,
    desc: '预约中',
  },
  WAIT_ACCEPT: {
    value: 1,
    desc: '待接受',
  },
  PROCESSING: {
    value: 2,
    desc: '进行中',
  },
  COMPLETED: {
    value: 3,
    desc: '已完成',
  },
  REJECTED: {
    value: 4,
    desc: '已拒绝',
  },
  REVOKED: {
    value: 5,
    desc: '已撤回',
  },
};

// 完成条件
export const TASK_COMPLETION_MODE_ENUM = {
  ANY_ONE: {
    value: 1,
    desc: '任一人完成',
  },
  ALL: {
    value: 2,
    desc: '全员完成',
  },
};

// 参与者状态
export const TASK_PARTICIPANT_STATUS_ENUM = {
  WAIT_ACCEPT: {
    value: 0,
    desc: '待接受',
  },
  ACCEPTED: {
    value: 1,
    desc: '已接受',
  },
  COMPLETED: {
    value: 2,
    desc: '已完成',
  },
  REJECTED: {
    value: 3,
    desc: '已拒绝',
  },
  SKIPPED: {
    value: 4,
    desc: '已跳过',
  },
};

// 任务事件类型
export const TASK_EVENT_TYPE_ENUM = {
  CREATE: {
    value: 1,
    desc: '创建',
  },
  INVITE: {
    value: 2,
    desc: '邀请',
  },
  ACCEPT: {
    value: 3,
    desc: '接受',
  },
  REJECT: {
    value: 4,
    desc: '拒绝',
  },
  COMPLETE: {
    value: 5,
    desc: '完成',
  },
  REVOKE: {
    value: 6,
    desc: '撤回',
  },
  REMIND: {
    value: 7,
    desc: '催办',
  },
  SCHEDULE_START: {
    value: 8,
    desc: '定时生效',
  },
  SKIP: {
    value: 9,
    desc: '跳过',
  },
};

// 任务状态对应的标签颜色（沿用 Ant Design 语义色）
export const TASK_STATUS_COLOR = {
  0: 'blue',
  1: 'gold',
  2: 'processing',
  3: 'green',
  4: 'red',
  5: 'default',
};

export default {
  TASK_STATUS_ENUM,
  TASK_COMPLETION_MODE_ENUM,
  TASK_PARTICIPANT_STATUS_ENUM,
  TASK_EVENT_TYPE_ENUM,
  TASK_STATUS_COLOR,
};
