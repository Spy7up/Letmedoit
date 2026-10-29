<!--
  * 让我做 · 运营概览
  * 数据来源：GET /dashboard/overview、POST /dashboard/trend
  * 口径：准时率 = 准时完成样本 / 完成样本，零样本显示 --
-->
<template>
  <div class="smart-detail-header">
    <a-page-header title="运营概览" :sub-title="subTitle">
      <template #extra>
        <a-radio-group v-model:value="days" @change="loadTrend" style="margin-right: 12px">
          <a-radio-button :value="7">近 7 天</a-radio-button>
          <a-radio-button :value="30">近 30 天</a-radio-button>
        </a-radio-group>
        <a-button type="primary" :loading="loading" @click="loadData">
          <template #icon>
            <ReloadOutlined />
          </template>
          刷新
        </a-button>
      </template>
    </a-page-header>
  </div>

  <a-spin :spinning="loading">
    <a-row :gutter="[12, 12]">
      <a-col :xs="24" :sm="12" :md="8" :xl="4" v-for="item in metricList" :key="item.label">
        <metric-card :label="item.label" :value="item.value" :suffix="item.suffix" :sub="item.sub" :tip="item.tip" />
      </a-col>
    </a-row>

    <a-row :gutter="[12, 12]" class="smart-margin-top10">
      <a-col :xs="24" :xl="16">
        <a-card size="small" :bordered="false" title="注册与任务趋势">
          <chart-panel v-if="hasTrend" :option="trendOption" height="300px" />
          <a-empty v-else description="暂无趋势数据" />
        </a-card>
      </a-col>
      <a-col :xs="24" :xl="8">
        <a-card size="small" :bordered="false" title="任务状态分布">
          <chart-panel v-if="statusList.length > 0" :option="statusOption" height="300px" />
          <a-empty v-else description="暂无任务" />
        </a-card>
      </a-col>
    </a-row>

    <a-card size="small" :bordered="false" class="smart-margin-top10" title="最新注册会员">
      <template #extra>
        <a @click="toMemberList">查看全部会员</a>
      </template>
      <a-table
        size="small"
        :dataSource="recentMemberList"
        :columns="recentColumns"
        rowKey="memberId"
        :pagination="false"
        :locale="{ emptyText: '暂无注册会员' }"
      >
        <template #bodyCell="{ text, record, column }">
          <template v-if="column.dataIndex === 'nickname'">
            <a-space>
              <a-avatar :size="24" :src="record.avatar || undefined">
                {{ (text || '会').slice(0, 1) }}
              </a-avatar>
              <span>{{ text || '未设置昵称' }}</span>
            </a-space>
          </template>
          <template v-if="column.dataIndex === 'action'">
            <a-button type="link" size="small" @click="toMemberDetail(record.memberId)">查看报表</a-button>
          </template>
        </template>
      </a-table>
    </a-card>
  </a-spin>
</template>

<script setup>
  import { ReloadOutlined } from '@ant-design/icons-vue';
  import { computed, onMounted, ref } from 'vue';
  import { useRouter } from 'vue-router';
  import { letmedoitDashboardApi } from '/@/api/business/letmedoit/dashboard-api';
  import ChartPanel from '/@/components/business/letmedoit/chart-panel.vue';
  import { TASK_STATUS_ENUM } from '/@/constants/business/letmedoit/task-const';
  import { smartSentry } from '/@/lib/smart-sentry';
  import MetricCard from '../components/metric-card.vue';

  const router = useRouter();
  const loading = ref(false);
  const days = ref(7);
  const overview = ref({});
  const trend = ref({ dateList: [], memberCountList: [], taskCountList: [], completedCountList: [] });

  const subTitle = computed(() => '全部有效业务数据 · 准时率按完成样本计算');

  // ---------------------------- 指标卡 ----------------------------
  function toPercent(value) {
    if (value === null || value === undefined) {
      return null;
    }
    return Number(value);
  }

  function toNumber(value) {
    return value === null || value === undefined ? null : Number(value);
  }

  const metricList = computed(() => {
    const data = overview.value || {};
    return [
      {
        label: '注册会员',
        value: toNumber(data.memberCount),
        sub: data.todayMemberCount ? `今日新增 ${data.todayMemberCount}` : '今日暂无新增',
        tip: '未删除的会员总数',
      },
      {
        label: '帮手关系对',
        value: toNumber(data.helperPairCount),
        sub: '按双方 ID 去重',
        tip: 't_helper 双向双写，按 LEAST/GREATEST 去重后的好友对数',
      },
      {
        label: '任务总数',
        value: toNumber(data.taskCount),
        sub: data.todayTaskCount ? `今日新增 ${data.todayTaskCount}` : '今日暂无新增',
        tip: '未删除的任务总数',
      },
      {
        label: '任务完成率',
        value: toPercent(data.taskCompletionRate),
        suffix: '%',
        sub: `${data.completedTaskCount || 0} / ${data.taskCount || 0} 个任务已完成`,
        tip: '已完成任务 / 任务总数；无任务时显示 --',
      },
      {
        label: '完成准时率',
        value: toPercent(data.onTimeRate),
        suffix: '%',
        sub: `${data.onTimeParticipantCount || 0} / ${data.completedParticipantCount || 0} 个完成样本准时`,
        tip: '完成时间不晚于任务截止时间的样本 / 有完成时间的完成样本',
      },
      {
        label: '待处理反馈',
        value: toNumber(data.pendingFeedbackCount),
        sub: '来自小程序问题与反馈',
        tip: 't_app_feedback.status = 0',
      },
    ];
  });

  // ---------------------------- 图表 ----------------------------
  const hasTrend = computed(() => (trend.value.dateList || []).length > 0);

  const trendOption = computed(() => ({
    color: ['#1677ff', '#52c41a', '#faad14'],
    tooltip: { trigger: 'axis' },
    legend: { data: ['注册会员', '新建任务', '完成任务'], right: 0, top: 0 },
    grid: { left: 8, right: 16, top: 40, bottom: 8, containLabel: true },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: trend.value.dateList || [],
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
        name: '注册会员',
        type: 'line',
        smooth: true,
        showSymbol: false,
        areaStyle: { opacity: 0.12 },
        data: trend.value.memberCountList || [],
      },
      {
        name: '新建任务',
        type: 'line',
        smooth: true,
        showSymbol: false,
        areaStyle: { opacity: 0.1 },
        data: trend.value.taskCountList || [],
      },
      {
        name: '完成任务',
        type: 'line',
        smooth: true,
        showSymbol: false,
        data: trend.value.completedCountList || [],
      },
    ],
  }));

  const statusList = computed(() => overview.value.taskStatusList || []);

  function statusLabel(status) {
    const target = Object.values(TASK_STATUS_ENUM).find((item) => item.value === status);
    return target ? target.desc : `状态 ${status}`;
  }

  const statusOption = computed(() => {
    const colorMap = { 0: '#1677ff', 1: '#faad14', 2: '#13c2c2', 3: '#52c41a', 4: '#ff4d4f', 5: '#bfbfbf' };
    return {
      tooltip: { trigger: 'item', formatter: '{b}：{c}（{d}%）' },
      legend: { bottom: 0, icon: 'circle' },
      series: [
        {
          type: 'pie',
          radius: ['45%', '68%'],
          center: ['50%', '45%'],
          avoidLabelOverlap: true,
          itemStyle: { borderColor: '#fff', borderWidth: 2 },
          label: { show: false },
          data: statusList.value.map((item) => ({
            name: statusLabel(item.status),
            value: item.count,
            itemStyle: { color: colorMap[item.status] || '#d9d9d9' },
          })),
        },
      ],
    };
  });

  // ---------------------------- 最新会员 ----------------------------
  const recentColumns = [
    { title: '会员', dataIndex: 'nickname', ellipsis: true },
    { title: '会员ID', dataIndex: 'memberId', width: 100 },
    { title: '注册时间', dataIndex: 'createTime', width: 170 },
    { title: '最近登录', dataIndex: 'lastLoginTime', width: 170 },
    { title: '操作', dataIndex: 'action', width: 100, fixed: 'right' },
  ];

  const recentMemberList = computed(() => overview.value.recentMemberList || []);

  function toMemberList() {
    router.push({ path: '/letmedoit/member' });
  }

  function toMemberDetail(memberId) {
    router.push({ path: '/letmedoit/member/detail', query: { memberId } });
  }

  // ---------------------------- 数据加载 ----------------------------
  async function loadTrend() {
    try {
      const result = await letmedoitDashboardApi.trend(days.value);
      trend.value = result.data || { dateList: [], memberCountList: [], taskCountList: [], completedCountList: [] };
    } catch (e) {
      smartSentry.captureError(e);
    }
  }

  async function loadData() {
    loading.value = true;
    try {
      const result = await letmedoitDashboardApi.overview();
      overview.value = result.data || {};
      await loadTrend();
    } catch (e) {
      smartSentry.captureError(e);
    } finally {
      loading.value = false;
    }
  }

  onMounted(loadData);
</script>
