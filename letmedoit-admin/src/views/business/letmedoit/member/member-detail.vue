<!--
  * 让我做 · 会员报表详情
  * 数据来源：GET /member/detail/{memberId}
  * 顶部是会员档案，中间是准时率仪表盘与近 14 天完成趋势，底部是帮手与任务明细
-->
<template>
  <a-spin :spinning="loading">
    <div class="smart-detail-header">
      <a-page-header :title="detail.nickname || '未设置昵称'" :sub-title="`会员ID ${detail.memberId || '-'}`">
        <template #avatar>
          <a-avatar :size="48" :src="detail.avatar || undefined">
            {{ (detail.nickname || '会').slice(0, 1) }}
          </a-avatar>
        </template>
        <template #extra>
          <a-button @click="backToList">
            <template #icon>
              <RollbackOutlined />
            </template>
            返回会员列表
          </a-button>
        </template>
        <a-descriptions size="small" :column="3">
          <a-descriptions-item label="邀请码">{{ detail.inviteCode || '--' }}</a-descriptions-item>
          <a-descriptions-item label="状态">
            <a-tag :color="detail.disabledFlag ? 'red' : 'green'">{{ detail.disabledFlag ? '已禁用' : '正常' }}</a-tag>
          </a-descriptions-item>
          <a-descriptions-item label="注册时间">{{ detail.createTime || '--' }}</a-descriptions-item>
          <a-descriptions-item label="最近登录">{{ detail.lastLoginTime || '--' }}</a-descriptions-item>
          <a-descriptions-item label="待处理帮手申请">{{ detail.pendingHelperRequestCount ?? 0 }}</a-descriptions-item>
          <a-descriptions-item label="帮手数">{{ detail.helperCount ?? 0 }}</a-descriptions-item>
        </a-descriptions>
      </a-page-header>
    </div>

    <a-row :gutter="[12, 12]">
      <a-col :xs="24" :sm="12" :md="8" :xl="4" v-for="item in metricList" :key="item.label">
        <metric-card :label="item.label" :value="item.value" :sub="item.sub" :tip="item.tip" />
      </a-col>
    </a-row>

    <a-row :gutter="[12, 12]" class="smart-margin-top10">
      <a-col :xs="24" :xl="8">
        <a-card size="small" :bordered="false" title="完成准时率">
          <div class="rate-gauge">
            <a-progress
              type="dashboard"
              :percent="onTimePercent"
              :width="160"
              :stroke-width="10"
              :gap-degree="90"
              :format="() => (hasRate ? `${onTimeRateText}%` : '--')"
            />
          </div>
          <div class="rate-desc">
            准时完成 {{ detail.onTimeCount ?? 0 }} / 完成样本 {{ detail.completedCount ?? 0 }}
          </div>
          <div class="rate-desc muted">完成时间不晚于任务截止时间才算准时</div>
        </a-card>
      </a-col>
      <a-col :xs="24" :xl="16">
        <a-card size="small" :bordered="false" title="近 14 天完成趋势">
          <chart-panel v-if="hasDayStat" :option="dayStatOption" height="270px" />
          <a-empty v-else description="近 14 天没有完成记录" />
        </a-card>
      </a-col>
    </a-row>

    <a-card size="small" :bordered="false" class="smart-margin-top10" title="帮手列表">
      <template #extra>
        <span class="muted">按单方向关系展示，双向双写各一行</span>
      </template>
      <a-table
        size="small"
        :dataSource="helperList"
        :columns="helperColumns"
        rowKey="helperMemberId"
        :pagination="false"
        :locale="{ emptyText: '还没有帮手' }"
      >
        <template #bodyCell="{ text, record, column }">
          <template v-if="column.dataIndex === 'nickname'">
            <a-space>
              <a-avatar :size="24" :src="record.avatar || undefined">
                {{ (text || '帮').slice(0, 1) }}
              </a-avatar>
              <a @click="toMemberDetail(record.helperMemberId)">{{ text || '未设置昵称' }}</a>
            </a-space>
          </template>
        </template>
      </a-table>
    </a-card>

    <a-card size="small" :bordered="false" class="smart-margin-top10" title="最近任务（最多 20 条）">
      <a-table
        size="small"
        :dataSource="taskList"
        :columns="taskColumns"
        rowKey="taskId"
        :pagination="false"
        :scroll="{ x: 1000 }"
        :locale="{ emptyText: '还没有任务记录' }"
      >
        <template #bodyCell="{ text, record, column }">
          <template v-if="column.dataIndex === 'title'">
            <a @click="toTaskDetail(record.taskId)">{{ text }}</a>
          </template>
          <template v-if="column.dataIndex === 'memberRole'">
            <a-tag :color="text === 'creator' ? 'blue' : 'purple'">
              {{ text === 'creator' ? '委托人' : '参与者' }}
            </a-tag>
          </template>
          <template v-if="column.dataIndex === 'status'">
            <a-tag :color="taskStatusColor(text)">{{ taskStatusLabel(text) }}</a-tag>
          </template>
          <template v-if="column.dataIndex === 'participantStatus'">
            <span v-if="record.memberRole !== 'participant'">--</span>
            <span v-else>{{ participantStatusLabel(text) }}</span>
          </template>
          <template v-if="column.dataIndex === 'onTimeFlag'">
            <span v-if="text === null || text === undefined" class="muted">--</span>
            <a-tag v-else :color="text ? 'green' : 'red'">{{ text ? '准时' : '逾期' }}</a-tag>
          </template>
        </template>
      </a-table>
    </a-card>
  </a-spin>
</template>

<script setup>
  import { RollbackOutlined } from '@ant-design/icons-vue';
  import { computed, onMounted, ref, watch } from 'vue';
  import { useRoute, useRouter } from 'vue-router';
  import { letmedoitMemberApi } from '/@/api/business/letmedoit/member-api';
  import ChartPanel from '/@/components/business/letmedoit/chart-panel.vue';
  import {
    TASK_PARTICIPANT_STATUS_ENUM,
    TASK_STATUS_COLOR,
    TASK_STATUS_ENUM,
  } from '/@/constants/business/letmedoit/task-const';
  import { smartSentry } from '/@/lib/smart-sentry';
  import MetricCard from '../components/metric-card.vue';

  const route = useRoute();
  const router = useRouter();

  const loading = ref(false);
  const memberId = ref(null);
  const detail = ref({});

  // ---------------------------- 指标 ----------------------------
  const hasRate = computed(() => detail.value.onTimeRate !== null && detail.value.onTimeRate !== undefined);
  const onTimeRateText = computed(() => (hasRate.value ? Number(detail.value.onTimeRate).toFixed(1) : '--'));
  const onTimePercent = computed(() => (hasRate.value ? Number(detail.value.onTimeRate) : 0));

  const metricList = computed(() => {
    const data = detail.value || {};
    return [
      {
        label: '帮手数',
        value: data.helperCount ?? 0,
        sub: '单向关系条数',
        tip: 't_helper.member_id = 当前会员且未删除',
      },
      {
        label: '发起任务',
        value: data.createdTaskCount ?? 0,
        sub: '作为委托人',
        tip: 't_task.creator_id = 当前会员且未删除',
      },
      {
        label: '参与任务',
        value: data.participantCount ?? 0,
        sub: '作为参与者',
        tip: '参与者关联的有效任务数',
      },
      {
        label: '完成样本',
        value: data.completedCount ?? 0,
        sub: '有完成时间',
        tip: '参与状态为已完成且 complete_time 不为空的样本',
      },
      {
        label: '准时完成',
        value: data.onTimeCount ?? 0,
        sub: '不晚于截止时间',
        tip: '完成时间 <= 任务截止时间',
      },
      {
        label: '准时率',
        value: hasRate.value ? onTimeRateText.value : null,
        suffix: hasRate.value ? '%' : '',
        sub: '零样本显示 --',
        tip: '准时完成 / 完成样本；没有完成样本时不显示百分比',
      },
    ];
  });

  // ---------------------------- 趋势图 ----------------------------
  const dayStatList = computed(() => detail.value.dayStatList || []);
  const hasDayStat = computed(() => dayStatList.value.some((item) => (item.completedCount || 0) > 0));

  const dayStatOption = computed(() => ({
    color: ['#1677ff', '#52c41a'],
    tooltip: { trigger: 'axis' },
    legend: { data: ['完成数', '准时数'], right: 0, top: 0 },
    grid: { left: 8, right: 16, top: 40, bottom: 8, containLabel: true },
    xAxis: {
      type: 'category',
      data: dayStatList.value.map((item) => item.statDate),
      axisLine: { lineStyle: { color: '#e8edf3' } },
      axisLabel: { color: '#8490a3' },
    },
    yAxis: {
      type: 'value',
      minInterval: 1,
      splitLine: { lineStyle: { color: '#f0f3f7' } },
      axisLabel: { color: '#8490a3' },
    },
    series: [
      {
        name: '完成数',
        type: 'bar',
        barMaxWidth: 18,
        itemStyle: { borderRadius: [4, 4, 0, 0] },
        data: dayStatList.value.map((item) => item.completedCount || 0),
      },
      {
        name: '准时数',
        type: 'line',
        smooth: true,
        symbolSize: 6,
        data: dayStatList.value.map((item) => item.onTimeCount || 0),
      },
    ],
  }));

  // ---------------------------- 明细表 ----------------------------
  const helperList = computed(() => detail.value.helperList || []);
  const helperColumns = [
    { title: '帮手', dataIndex: 'nickname', ellipsis: true },
    { title: '备注名', dataIndex: 'remark', width: 140 },
    { title: '邀请码', dataIndex: 'inviteCode', width: 110 },
    { title: '建立时间', dataIndex: 'createTime', width: 170 },
  ];

  const taskList = computed(() => detail.value.taskList || []);
  const taskColumns = [
    { title: '任务', dataIndex: 'title', ellipsis: true },
    { title: '身份', dataIndex: 'memberRole', width: 90 },
    { title: '任务状态', dataIndex: 'status', width: 100 },
    { title: '参与状态', dataIndex: 'participantStatus', width: 100 },
    { title: '完成时间', dataIndex: 'completeTime', width: 170 },
    { title: '是否准时', dataIndex: 'onTimeFlag', width: 100 },
    { title: '截止时间', dataIndex: 'deadline', width: 170 },
  ];

  function taskStatusLabel(status) {
    const target = Object.values(TASK_STATUS_ENUM).find((item) => item.value === status);
    return target ? target.desc : `状态 ${status}`;
  }

  function taskStatusColor(status) {
    return TASK_STATUS_COLOR[status] || 'default';
  }

  function participantStatusLabel(status) {
    const target = Object.values(TASK_PARTICIPANT_STATUS_ENUM).find((item) => item.value === status);
    return target ? target.desc : '--';
  }

  // ---------------------------- 跳转 ----------------------------
  function backToList() {
    router.push({ path: '/letmedoit/member' });
  }

  function toMemberDetail(id) {
    if (id && id !== memberId.value) {
      router.push({ path: '/letmedoit/member/detail', query: { memberId: id } });
    }
  }

  function toTaskDetail(taskId) {
    router.push({ path: '/letmedoit/task/detail', query: { taskId } });
  }

  // ---------------------------- 加载 ----------------------------
  async function loadDetail() {
    if (!memberId.value) {
      return;
    }
    loading.value = true;
    try {
      const result = await letmedoitMemberApi.detail(memberId.value);
      detail.value = result.data || {};
    } catch (e) {
      smartSentry.captureError(e);
    } finally {
      loading.value = false;
    }
  }

  function readMemberId() {
    const queryMemberId = route.query.memberId;
    memberId.value = queryMemberId ? Number(queryMemberId) : null;
  }

  watch(
    () => route.query.memberId,
    () => {
      readMemberId();
      loadDetail();
    }
  );

  onMounted(() => {
    readMemberId();
    loadDetail();
  });
</script>

<style lang="less" scoped>
  .rate-gauge {
    display: flex;
    justify-content: center;
    padding-top: 4px;
  }

  .rate-desc {
    margin-top: 6px;
    text-align: center;
    color: rgba(0, 0, 0, 0.65);
    font-size: 13px;
  }

  .muted {
    color: rgba(0, 0, 0, 0.45);
    font-size: 12px;
  }
</style>
